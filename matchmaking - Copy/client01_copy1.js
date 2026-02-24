const { io } = require("socket.io-client");
const readline = require("readline");

// Setup keyboard input
readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
  process.stdin.setRawMode(true);
}

// Helper to create a player and join the queue
function createPlayer(userId, genres) {
  const socket = io("http://localhost:3000");

  socket.on("connect", () => {
    console.log(`${userId} connected with socket ID: ${socket.id}`);
    socket.emit("joinQueue", { userId, genres });
  });

  socket.on("matchFound", (data) => {
    console.log(`--- ${userId} MATCH FOUND ---`);
    console.log(
      `${userId} matched with ${data.opponentId} in room: ${data.roomName} (Similarity: ${data.similarity})`
    );

    socket.matchId = data.matchId;
    socket.roomName = data.roomName;
  });

  // Quiz start signal
  socket.on("readyForQuiz", ({ matchId }) => {
    console.log(`${userId} is ready for quiz in match ${matchId}`);
  });

  // Receive questions
  socket.on("question", ({ matchId, question }) => {
    console.log(`\n--- ${userId} RECEIVED QUESTION ---`);
    console.log(`Q${question.id}: ${question.text}`);
    question.options.forEach((opt, i) => console.log(`${i + 1}. ${opt}`));

    console.log("Press 1–4 to answer, or E to end match.");

    // Listen for keypress answers
    process.stdin.once("keypress", (str, key) => {
      if (["1", "2", "3", "4"].includes(str)) {
        const selectedOption = question.options[parseInt(str) - 1];
        console.log(`${userId} answered: ${selectedOption}`);
        socket.emit("submitAnswer", {
          matchId,
          questionId: question.id,
          selectedOption
        });
      } else if (key.name === "e") {
        if (socket.matchId) {
          console.log(`Manual end triggered by ${userId} with key E`);
          socket.emit("endMatch", { matchId: socket.matchId });
        }
      }
    });
  });

  // Match ended
  socket.on("matchEnded", ({ matchId }) => {
    console.log(`--- ${userId} MATCH ENDED ---`);
    console.log(`${userId}'s match ${matchId} has ended.`);
    delete socket.matchId;
    delete socket.roomName;
  });

  // Opponent disconnected
  socket.on("opponentDisconnected", ({ matchId, opponentId }) => {
    console.log(`!!! ${userId} OPPONENT DISCONNECTED !!!`);
    console.log(`${userId}'s opponent ${opponentId} disconnected in match ${matchId}.`);
    delete socket.matchId;
    delete socket.roomName;
  });

  socket.on("disconnect", () => {
    console.log(`${userId} disconnected.`);
  });

  socket.on("queueTimeout", (data) => {
    console.log(`--- ${userId} QUEUE TIMEOUT ---`);
    console.log(`${userId}: ${data.message}`);
  });

  return socket;
}

// ✅ Only create 2 players for testing
const player1 = createPlayer("Player1", [1, 0, 1, 1, 0, 1, 0, 0, 0, 0]);
const player2 = createPlayer("Player2", [1, 1, 0, 0, 0, 0, 0, 0, 0, 0]);

socket.on("question", ({ matchId, question }) => {
  console.log(`\n--- ${userId} RECEIVED QUESTION ---`);
  console.log(`Q${question.id}: ${question.text}`);
  question.options.forEach((opt, i) => console.log(`${i + 1}. ${opt}`));

  console.log("Press 1–4 to answer, or E to end match.");

  // Listen for keypress answers
  process.stdin.once("keypress", (str, key) => {
    if (["1", "2", "3", "4"].includes(str)) {
      const selectedOption = question.options[parseInt(str) - 1];
      console.log(`${userId} answered: ${selectedOption}`);
      socket.emit("submitAnswer", {
        matchId,
        questionId: question.id,
        selectedOption
      });
    } else if (key.name === "e") {
      if (socket.matchId) {
        console.log(`Manual end triggered by ${userId} with key E`);
        socket.emit("endMatch", { matchId: socket.matchId });
      }
    }
  });
});