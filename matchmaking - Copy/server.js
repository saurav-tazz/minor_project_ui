const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Cosine similarity helper
function cosineSimilarity(vecA, vecB) {
  if (!vecA || !vecB || vecA.length !== vecB.length) return 0;
  const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
  const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
  const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
  if (magnitudeA === 0 || magnitudeB === 0) return 0;
  return dotProduct / (magnitudeA * magnitudeB);
}

// Queue of waiting players + matches
let waitingPlayers = [];
let activeMatches = {};

io.on("connection", (socket) => {
  console.log("Player connected:", socket.id);

  socket.on("joinQueue", ({ userId, genres }) => {
    console.log(`${userId} joined queue with genres:`, genres);


    let matched = false;
    for (let i = 0; i < waitingPlayers.length; i++) {
      const other = waitingPlayers[i];
      const similarity = cosineSimilarity(genres, other.genres);
      console.log(`Similarity between ${userId} and ${other.userId}:`, similarity);
      
      if (similarity >= 0.7) { // threshold
        const matchId = Date.now().toString();
        const roomName = 'match_${matchId}';

        // Track active match
        activeMatches[matchId] = {
          players: [userId, other.userId],
          similarity,
          startedAt: new Date()
        };
        
        // Put both players into the same room
        socket.join(roomName);
        io.sockets.sockets.get(other.socketId)?.join(roomName);

        //Notify both players
        io.to(socket.id).emit("matchFound", { matchId, opponent: other.userId, similarity });
        io.to(other.socketId).emit("matchFound", { matchId, opponent: userId, similarity });
        
        //Remove matched players from queue
        waitingPlayers.splice(i, 1); // remove matched player
        matched = true;
        break;
      }
    }

    if (!matched) {
      waitingPlayers.push({ userId, socketId: socket.id, genres });
    }
  });

  socket.on("endMatch", ({ matchId, requeue }) => {
  const match = activeMatches[matchId];
  if (!match) 
    {
      console.log("No match found with ID:", matchId);
      return;
    }
    
  console.log(`Match ${matchId} ended by ${socket.id}`);

  // Notify both players that the match ended
  io.to(match.room).emit("matchEnded", { matchId });

  // Remove the match from activeMatches
  delete activeMatches[matchId];

  // If requeue is true, put players back into waitingPlayers
  if (requeue) {
    match.players.forEach(playerId => {
      const playerSocket = [...io.sockets.sockets.values()]
        .find(s => s.handshake.query.userId === playerId);
      if (playerSocket) {
        waitingPlayers.push({
          userId: playerId,
          socketId: playerSocket.id,
          genres: playerSocket.handshake.query.genres // or store genres elsewhere
        });
      }
    });
  }
});

  socket.on("disconnect", () => {
    //remove from queue
    waitingPlayers = waitingPlayers.filter(p => p.socketId !== socket.id);
    
    // Clean up active matches if needed
    for (const [matchId, match] of Object.entries(activeMatches)) {
      if (match.players.includes(socket.id)) {
        delete activeMatches[matchId];
        console.log(`Match ${matchId} ended because ${socket.id} disconnected`);
      }
    }

    console.log("Player disconnected:", socket.id);
  });
});

server.listen(3000, () => {
  console.log("Matchmaking server running on http://localhost:3000");
});