const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Adjust this for production security
    methods: ["GET", "POST"]
  }
});

// Cosine similarity helper function
function cosineSimilarity(vecA, vecB) {
  if (!vecA ||!vecB || vecA.length!== vecB.length) return 0;
  const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
  const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
  const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
  if (magnitudeA === 0 || magnitudeB === 0) return 0;
  return dotProduct / (magnitudeA * magnitudeB);
}

//temporary question bank
const sampleQuestions = [
  {
    question: "Capital of France?",
    options: ["Paris", "London", "Berlin", "Rome"],
    correctIndex: 0
  },
  {
    question: "2 + 2?",
    options: ["3", "4", "5", "6"],
    correctIndex: 1
  }
];


// Queue of waiting players
// Stores comprehensive player info: { userId, socketId, genres }
let waitingPlayers = [];

// Active matches
// Stores: { matchId: { players: [{userId, socketId, genres},...], roomName, similarity, startedAt } }
let activeMatches = {};

io.on("connection", (socket) => {
  console.log("Player connected:", socket.id);

  // --- Event: joinQueue ---
  socket.on("joinQueue", ({ userId, genres }) => {
    console.log(`${userId} (Socket: ${socket.id}) joined queue with genres:`, genres);

    // Remove player if already in queue (e.g., if they rejoin queue)
    waitingPlayers = waitingPlayers.filter(p => p.userId!== userId);

    let matched = false;
    for (let i = 0; i < waitingPlayers.length; i++) {
      const otherPlayer = waitingPlayers[i];
      const similarity = cosineSimilarity(genres, otherPlayer.genres);
      console.log(`Similarity between ${userId} and ${otherPlayer.userId}:`, similarity);

      if (similarity >= 0.7) { 
        const matchId = `match_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        const roomName = matchId;

        // activeMatches[matchId] = {
        //   players: [
        //     { userId: userId, socketId: socket.id, genres: genres },
        //     { userId: otherPlayer.userId, socketId: otherPlayer.socketId, genres: otherPlayer.genres }
        //   ],
        //   roomName: roomName,
        //   similarity: similarity,
        //   startedAt: new Date()
        // };
        activeMatches[matchId] = {
  players: [
  { 
    userId: userId, 
    socketId: socket.id, 
    genres: genres, 
    score: 0, 
    answered: false 
  },
  { 
    userId: otherPlayer.userId, 
    socketId: otherPlayer.socketId, 
    genres: otherPlayer.genres, 
    score: 0, 
    answered: false 
  }
],

  roomName,
  similarity,
  startedAt: new Date(),
  currentQuestionIndex: 0,
  questions: [],      // will be filled
  timer: null,
  questionDuration: 15
};
activeMatches[matchId].questions = sampleQuestions;



        socket.join(roomName);
        io.sockets.sockets.get(otherPlayer.socketId)?.join(roomName);

        io.to(socket.id).emit("matchFound", { matchId, opponentId: otherPlayer.userId, similarity, roomName });
        io.to(otherPlayer.socketId).emit("matchFound", { matchId, opponentId: userId, similarity, roomName });
        startGame(matchId);


        clearTimeout(otherPlayer.timeout);
        matched = true;
        waitingPlayers.splice(i, 1); 
        break; 
      }
    }

    if (!matched) {

        const player = {userId, socketId: socket.id, genres };

        // Add timeout logic (e.g., 30 seconds)
    player.timeout = setTimeout(() => {
      waitingPlayers = waitingPlayers.filter(p => p.userId !== userId);
      io.to(socket.id).emit("queueTimeout", { message: "No match found, please try again." });
      console.log(`${userId} timed out and removed from queue`);
    }, 30000);
    
      waitingPlayers.push(player);
      console.log(`${userId} added to queue. Current queue length: ${waitingPlayers.length}`);
    } else {
      console.log(`Match found for ${userId}. Current queue length: ${waitingPlayers.length}`);
    }
    console.log("Waiting players:", waitingPlayers.map(p => p.userId));
  });

  //submit answers
  socket.on("submitAnswer", ({ matchId, answerIndex }) => {
  const match = activeMatches[matchId];
  if (!match) return;

  const player = match.players.find(p => p.socketId === socket.id);
  if (!player || player.answered) return;

  const question = match.questions[match.currentQuestionIndex];

  if (answerIndex === question.correctIndex) {
    player.score += 10;
  } else {
    player.score -= 5;
  }

  player.answered = true;

  io.to(match.roomName).emit("scoreUpdate", {
    scores: match.players.map(p => ({
      userId: p.userId,
      score: p.score
    }))
  });

  const allAnswered = match.players.every(p => p.answered);

  if (allAnswered) {
    clearTimeout(match.timer);
    nextQuestion(matchId);
  }
});


  // --- Event: endMatch ---
  // No 'requeue' flag needed on the server side now, as it's not handled.
  socket.on("endMatch", ({ matchId }) => { // Removed 'requeue' from destructuring
    const match = activeMatches[matchId];
    if (!match) {
      console.log("No match found with ID:", matchId);
      return;
    }

    console.log(`Match ${matchId} ended, triggered by ${socket.id}.`); // Adjusted log message

    io.to(match.roomName).emit("matchEnded", { matchId });

    match.players.forEach(p => {
      const playerSocket = io.sockets.sockets.get(p.socketId);
      if (playerSocket) {
        playerSocket.leave(match.roomName);
      }
    });

    delete activeMatches[matchId];

    // Removed the 'if (requeue)' block entirely
  });

  // --- Event: disconnect ---
  socket.on("disconnect", () => {
    console.log("Player disconnected:", socket.id);

    const disconnectedPlayerIndex = waitingPlayers.findIndex(p => p.socketId === socket.id);
    if (disconnectedPlayerIndex!== -1) {
      const disconnectedPlayer = waitingPlayers[disconnectedPlayerIndex];
      waitingPlayers.splice(disconnectedPlayerIndex, 1);
      console.log(`${disconnectedPlayer.userId} removed from queue. Current queue length: ${waitingPlayers.length}`);
    }

    for (const matchId in activeMatches) {
      const match = activeMatches[matchId];
      const playerInMatch = match.players.find(p => p.socketId === socket.id);
      if (playerInMatch) {
        console.log(`Player ${playerInMatch.userId} disconnected. Ending match ${matchId}.`);
        
        match.players.forEach(p => {
          if (p.socketId!== socket.id) {
            io.to(p.socketId).emit("opponentDisconnected", { matchId, opponentId: playerInMatch.userId });
            const playerSocket = io.sockets.sockets.get(p.socketId);
            if (playerSocket) {
              playerSocket.leave(match.roomName);
            }
          }
        });
        delete activeMatches[matchId];
        console.log(`Match ${matchId} removed.`);
        break; 
      }
    }
    console.log("Waiting players after disconnect:", waitingPlayers.map(p => p.userId));
  });
});


function startGame(matchId) {
  const match = activeMatches[matchId];
  if (!match) return;
  sendQuestion(matchId);
}

function sendQuestion(matchId) {
  const match = activeMatches[matchId];
  if (!match) return;

  const question = match.questions[match.currentQuestionIndex];

  if (!question) {
    endGame(matchId);
    return;
  }

  match.players.forEach(p => p.answered = false);

  io.to(match.roomName).emit("newQuestion", {
    index: match.currentQuestionIndex,
    question: question.question,
    options: question.options,
    duration: match.questionDuration
  });

  startTimer(matchId);
}

function startTimer(matchId) {
  const match = activeMatches[matchId];
  if (!match) return;

  match.timer = setTimeout(() => {
    nextQuestion(matchId);
  }, match.questionDuration * 1000);
}

function nextQuestion(matchId) {
  const match = activeMatches[matchId];
  if (!match) return;

  match.currentQuestionIndex++;

  if (match.currentQuestionIndex >= match.questions.length) {
    endGame(matchId);
  } else {
    sendQuestion(matchId);
  }
}

function endGame(matchId) {
  const match = activeMatches[matchId];
  if (!match) return;

  const sorted = [...match.players].sort((a, b) => b.score - a.score);

  io.to(match.roomName).emit("gameOver", {
    results: match.players.map(p => ({
      userId: p.userId,
      score: p.score
    })),
    winner: sorted[0].score === sorted[1].score ? null : sorted[0].userId
  });

  delete activeMatches[matchId];
}

server.listen(3000, () => {
  console.log("Matchmaking server running on http://localhost:3000");
});