const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*", // Adjust this for production security
    methods: ["GET", "POST"],
  },
});

// --- Cosine similarity helper function ---
function cosineSimilarity(vecA, vecB) {
  if (!vecA || !vecB || vecA.length !== vecB.length) return 0;

  const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
  const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
  const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));

  if (magnitudeA === 0 || magnitudeB === 0) return 0;

  return dotProduct / (magnitudeA * magnitudeB);
}

// --- Queues and Matches ---
let waitingPlayers = []; // { userId, socketId, genres, timeout }
let activeMatches = {};  // { matchId: { players, roomName, similarity, startedAt } }

io.on("connection", (socket) => {
  console.log("Player connected:", socket.id);

  // --- Event: joinQueue ---
  socket.on("joinQueue", ({ userId, genres }) => {
    console.log(`${userId} (Socket: ${socket.id}) joined queue with genres:`, genres);

    // Remove player if already in queue
    waitingPlayers = waitingPlayers.filter(p => p.userId !== userId);

    let matched = false;

    for (let i = 0; i < waitingPlayers.length; i++) {
      const otherPlayer = waitingPlayers[i];
      const similarity = cosineSimilarity(genres, otherPlayer.genres);

      console.log(`Similarity between ${userId} and ${otherPlayer.userId}:`, similarity);

      if (similarity >= 0.7) {
        const matchId = `match_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        const roomName = matchId;

        activeMatches[matchId] = {
          players: [
            { userId, socketId: socket.id, genres },
            { userId: otherPlayer.userId, socketId: otherPlayer.socketId, genres: otherPlayer.genres },
          ],
          roomName,
          similarity,
          startedAt: new Date(),
//new1
          questions: [],
  currentQuestionIndex: 0,
  scores: {
    [userId]: 0,
    [otherPlayer.userId]: 0
  },
  answers: {} // to track who answered
  //new1
        };

        //new3
        activeMatches[matchId].questions = [
  {
    id: 1,
    text: "Capital of France?",
    options: ["Berlin", "Madrid", "Paris", "Rome"],
    correctAnswer: "Paris"
  },
  {
    id: 2,
    text: "2 + 2 = ?",
    options: ["3", "4", "5", "6"],
    correctAnswer: "4"
  }
];
//new3

        socket.join(roomName);
        io.sockets.sockets.get(otherPlayer.socketId)?.join(roomName);

        io.to(socket.id).emit("matchFound", {
          matchId,
          opponentId: otherPlayer.userId,
          similarity,
          roomName,
        });

        //new2
        io.to(roomName).emit("readyForQuiz", { matchId });
        // new2

        //new4
        const match = activeMatches[matchId];
const firstQuestion = match.questions[0];

io.to(roomName).emit("question", {
  matchId,
  question: {
    id: firstQuestion.id,
    text: firstQuestion.text,
    options: firstQuestion.options
  }
});
//new4
        io.to(otherPlayer.socketId).emit("matchFound", {
          matchId,
          opponentId: userId,
          similarity,
          roomName,
        });

        clearTimeout(otherPlayer.timeout);
        matched = true;
        waitingPlayers.splice(i, 1);
        break;
      }
    }

    if (!matched) {
      const player = { userId, socketId: socket.id, genres };

      // Timeout logic (30 seconds)
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

  //new5
  // Handle submitted answers
socket.on("submitAnswer", ({ matchId, questionId, selectedOption }) => {
  const match = activeMatches[matchId];
  if (!match) return;

  const currentQ = match.questions[match.currentQuestionIndex];
  if (!currentQ) return;

  // Check correctness
  if (selectedOption === currentQ.correctAnswer) {
    const player = match.players.find(p => p.socketId === socket.id);
    if (player) {
      match.scores[player.userId] += 1;
      console.log(`${player.userId} answered correctly!`);
    }
  } else {
    console.log(`Wrong answer: ${selectedOption}`);
  }

  // Move to next question
  match.currentQuestionIndex++;
  if (match.currentQuestionIndex < match.questions.length) {
    const nextQ = match.questions[match.currentQuestionIndex];
    io.to(match.roomName).emit("question", {
      matchId,
      question: {
        id: nextQ.id,
        text: nextQ.text,
        options: nextQ.options
      }
    });
  } else {
    // Quiz finished
    io.to(match.roomName).emit("matchEnded", {
      matchId,
      scores: match.scores
    });
    delete activeMatches[matchId];
  }
});
//new5

  // --- Event: endMatch ---
  socket.on("endMatch", ({ matchId }) => {
    const match = activeMatches[matchId];
    if (!match) {
      console.log("No match found with ID:", matchId);
      return;
    }

    console.log(`Match ${matchId} ended, triggered by ${socket.id}.`);

    io.to(match.roomName).emit("matchEnded", { matchId });

    match.players.forEach(p => {
      const playerSocket = io.sockets.sockets.get(p.socketId);
      if (playerSocket) {
        playerSocket.leave(match.roomName);
      }
    });

    delete activeMatches[matchId];
  });

  // --- Event: disconnect ---
  socket.on("disconnect", () => {
    console.log("Player disconnected:", socket.id);

    const disconnectedPlayerIndex = waitingPlayers.findIndex(p => p.socketId === socket.id);
    if (disconnectedPlayerIndex !== -1) {
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
          if (p.socketId !== socket.id) {
            io.to(p.socketId).emit("opponentDisconnected", {
              matchId,
              opponentId: playerInMatch.userId,
            });

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

server.listen(3000, () => {
  console.log("Matchmaking server running on http://localhost:3000");
});

const questionSelection = require("./questionSelection");
questionSelection(io, activeMatches);