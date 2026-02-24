module.exports = function(io, activeMatches) {
  io.on("connection", (socket) => {
    // Player submits their 5 chosen questions
    socket.on("questionsSelected", ({ matchId, userId, selectedQuestions }) => {
      const match = activeMatches[matchId];
      if (!match) {
        console.log("No active match with ID:", matchId);
        return;
      }

      // Save player’s selected questions
      const player = match.players.find(p => p.userId === userId);
      if (player) {
        player.selectedQuestions = selectedQuestions;
        console.log(`${userId} submitted questions for match ${matchId}`);
      }

      // Check if both players have submitted
      const allSubmitted = match.players.every(p => p.selectedQuestions);
      if (allSubmitted) {
        console.log(`Both players ready in match ${matchId}. Starting match...`);

        io.to(match.roomName).emit("matchStart", {
          matchId,
          players: match.players.map(p => ({
            userId: p.userId,
            questions: p.selectedQuestions
          }))
        });
      }
    });
  });
};