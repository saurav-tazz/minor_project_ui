const { io } = require("socket.io-client");

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

    // Simulate game play and then end the match after 2 seconds
    setTimeout(() => {
      console.log(`Game started for ${userId} in room ${socket.roomName}.`);
      socket.emit("endMatch", { matchId: socket.matchId });
    }, 2000);
  });

  //new2
  socket.emit("questionsSelected", {
  matchId: socket.matchId,
  userId: "Player1", // or whichever player
  selectedQuestions: [1, 3, 5, 7, 9] // IDs or text of chosen questions
});

socket.on("matchStart", (data) => {
  console.log(`Match ${data.matchId} started!`);
  console.log("Players and their questions:", data.players);
});
  //new2
  //new1
  socket.emit("submitAnswer", {
  matchId: socket.matchId,
  questionId: 1,
  selectedOption: "Paris"
});
//new1



  socket.on("matchEnded", ({ matchId }) => {
    console.log(`--- ${userId} MATCH ENDED ---`);
    console.log(`${userId}'s match ${matchId} has ended. Player is now in the lobby.`);

    delete socket.matchId;
    delete socket.roomName;

    // In a real app, this is where the player would return to a lobby or "game over" screen
  });

  socket.on("opponentDisconnected", ({ matchId, opponentId }) => {
    console.log(`!!! ${userId} OPPONENT DISCONNECTED !!!`);
    console.log(
      `${userId}'s opponent ${opponentId} disconnected in match ${matchId}. Player is now in the lobby.`
    );

    delete socket.matchId;
    delete socket.roomName;
  });

  socket.on("disconnect", () => {
    console.log(`${userId} disconnected.`);
  });

  socket.on("queueTimeout", (data) => {
    console.log(`--- ${userId} QUEUE TIMEOUT ---`);
    console.log(`${userId}: ${data.message}`);

    // In a real app, show "No match found" and return to lobby
  });

  return socket;
}

// Create and connect multiple players with different genre preferences
const player1 = createPlayer("Player1", [1, 0, 1, 1, 0, 1, 0, 0, 0, 0]);
const player2 = createPlayer("Player2", [1, 1, 0, 0, 0, 0, 0, 0, 0, 0]);
const player3 = createPlayer("Player3", [1, 0, 1, 0, 0, 1, 0, 0, 0, 0]);
const player4 = createPlayer("Player4", [0, 0, 0, 1, 1, 0, 0, 0, 0, 0]);
const player5 = createPlayer("Player5", [1, 0, 0, 1, 1, 0, 0, 0, 0, 0]);

// You can still test disconnects manually
// setTimeout(() => {
//   console.log("\nSimulating Player3 disconnecting after 7 seconds...");
//   player3.disconnect();
// }, 7000);