import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // =========================
  // TEMPORARY FRONTEND STATE
  // =========================
  // TODO (Backend Integration):
  // Replace these hardcoded values with:
  //  - Data received from backend (Socket.IO event: "matchResult")
  //  - OR values passed from QuizScreen after quiz submission

  String playerName = "Player123";        // TODO: replace with current user name from backend
  String opponentName = "OpponentXYZ";    // TODO: replace with opponent name from backend

  int playerCorrect = 2;   // TODO: backend: number of correct answers from server result
  int opponentCorrect = 3; // TODO: backend: opponent correct answers

  int playerPoints = 285;  // TODO: backend: final points calculated by server
  int opponentPoints = 420; // TODO: backend: opponent final points

  // =========================
  // LIFECYCLE
  // =========================
  @override
  void initState() {
    super.initState();

    // TODO (Backend Integration - Socket.IO):
    // 1. Connect to socket server here (if not already globally connected)
    // 2. Listen for match result event:
    //
    // socket.on("matchResult", (data) {
    //   setState(() {
    //     playerName = data["me"]["name"];
    //     opponentName = data["opponent"]["name"];
    //     playerCorrect = data["me"]["correct"];
    //     opponentCorrect = data["opponent"]["correct"];
    //     playerPoints = data["me"]["points"];
    //     opponentPoints = data["opponent"]["points"];
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final bool playerWon = playerPoints > opponentPoints;
    final bool draw = playerPoints == opponentPoints;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF05B4FF), Color(0xFF0277FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Crown Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 12),

              Text(
                draw
                    ? "It's a Draw!"
                    : playerWon
                    ? "Victory!"
                    : "Defeat",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                draw
                    ? "Well played both!"
                    : playerWon
                    ? "$playerName Wins!"
                    : "$opponentName Wins!",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _playerCard(
                        name: playerName,
                        tag: "P1",
                        correct: playerCorrect,
                        total: 5, // TODO (Backend): total questions from server
                        points: playerPoints,
                        isWinner: playerWon && !draw,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _playerCard(
                        name: opponentName,
                        tag: "P2",
                        correct: opponentCorrect,
                        total: 5, // TODO (Backend): total questions from server
                        points: opponentPoints,
                        isWinner: !playerWon && !draw,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO (Backend Integration):
                        // 1. Emit "playAgain" or "rejoinQueue" socket event
                        // socket.emit("rejoinQueue", { genres: selectedGenres });
                        //
                        // 2. Navigate back to matchmaking screen
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Play Again"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO (Backend Integration):
                        // 1. Optionally emit "leaveMatch" to server
                        // socket.emit("leaveMatch");
                        //
                        // 2. Navigate to HomeScreen
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text("Back to Home"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF017BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerCard({
    required String name,
    required String tag,
    required int correct,
    required int total,
    required int points,
    required bool isWinner,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWinner ? const Color(0xFFFFC107) : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Text(tag, style: const TextStyle(color: Colors.white)),
              ),
              if (isWinner)
                const Positioned(
                  right: -4,
                  top: -4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFFFFC107),
                    child: Icon(Icons.emoji_events, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 12),

          _infoBox(
            icon: Icons.check_circle,
            title: "Correct Answers",
            value: "$correct/$total",
            valueColor: Colors.green,
          ),

          const SizedBox(height: 10),

          _infoBox(
            icon: Icons.emoji_events_outlined,
            title: "Points",
            value: "$points",
            valueColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}