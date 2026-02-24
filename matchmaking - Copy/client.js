const { io } = require("socket.io-client");

// Connect two players
const player1 = io("http://localhost:3000");
const player2 = io("http://localhost:3000");
const player3 = io("http://localhost:3000");


player1.on("connect", () => {
  player1.emit("joinQueue", { userId: "Player1", genres: [1,0,1,0,0,1,0,0,0,0] });
});

player2.on("connect", () => {
  player2.emit("joinQueue", { userId: "Player2", genres: [1,1,0,0,0,0,0,0,0,0] });
});

player3.on("connect", () => {
  // 🔹 Very similar to Player1
  player3.emit("joinQueue", { userId: "Player3", genres: [1,0,1,0,0,1,0,0,0,0] });
});

player1.on("matchFound", (data) => {
  console.log("Player1 matched:", data);

  // Trigger endMatch after 5 seconds
  // setTimeout(() => {
  //   player1.emit("endMatch", { matchId: data.matchId, requeue: true });
  //   console.log("Player1 ended match:", data.matchId);
  // }, 5000);
});


player2.on("matchFound", (data) => {
  console.log("Player2 matched:", data);
});

player3.on("matchFound", (data) => {
  console.log("Player3 matched:", data);
});

[player1, player2, player3].forEach(player => {
  player.on("matchEnded", ({ matchId }) => {
    console.log("Match ended for", player.io.opts.query?.userId || player.id, ":", matchId);
  });
});

