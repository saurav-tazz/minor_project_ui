import 'package:flutter/material.dart';
// import 'package:quiz_duel/pages/homescreen.dart';

class ResultScreen extends StatefulWidget {
  // data matches backend: { results: [{userId, name, matchScore}], winner: id }
  final Map<String, dynamic> gameResults;
  final dynamic socket;

  const ResultScreen({
    super.key,
    required this.gameResults,
    required this.socket,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String playerName, opponentName;
  late int playerPoints, opponentPoints;
  late bool playerWon, draw;

  @override
  void initState() {
    super.initState();
    _parseResults();
  }

  void _parseResults() {
    final List<dynamic> results = widget.gameResults['results'];
    final String? winnerId = widget.gameResults['winner'];

    // Use the socket ID to identify which result entry belongs to the local player
    final String myId = widget.socket.id ?? "";

    // Find "Me" and "Opponent" in the results array
    final me = results.firstWhere(
      (user) => user['userId'] == myId,
      orElse: () => results[0], // Fallback to first entry if ID mismatch
    );
    final op = results.firstWhere(
      (user) => user['userId'] != me['userId'],
      orElse: () => results.length > 1
          ? results[1]
          : {'name': 'Opponent', 'matchScore': 0},
    );

    playerName = me['name'] ?? "You";
    opponentName = op['name'] ?? "Opponent";

    // matchScore calculated by backend: (correct * 10) + (wrong * -5)
    playerPoints = me['matchScore'] ?? 0;
    opponentPoints = op['matchScore'] ?? 0;

    draw = winnerId == null || winnerId == "draw";
    playerWon = !draw && winnerId == me['userId'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: playerWon
                ? [
                    const Color(0xFF00C853),
                    const Color(0xFFB2FF59),
                  ] // Green for Win
                : (draw
                      ? [
                          const Color(0xFF607D8B),
                          const Color(0xFFCFD8DC),
                        ] // Blue-Grey for Draw
                      : [
                          const Color(0xFFFF5252),
                          const Color(0xFFFF1744),
                        ]), // Red for Loss
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 50),
              _buildHeaderIcon(),
              const SizedBox(height: 20),
              Text(
                draw ? "IT'S A DRAW!" : (playerWon ? "VICTORY!" : "DEFEAT"),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _playerCard(
                        name: playerName,
                        tag: "YOU",
                        points: playerPoints,
                        isWinner: playerWon,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "VS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _playerCard(
                        name: opponentName,
                        tag: "OPP",
                        points: opponentPoints,
                        isWinner: !playerWon && !draw,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
              ],
            ),
            child: Icon(
              playerWon
                  ? Icons.emoji_events
                  : (draw
                        ? Icons.handshake
                        : Icons.sentiment_very_dissatisfied),
              size: 80,
              color: playerWon
                  ? Colors.amber
                  : (draw ? Colors.blueGrey : Colors.redAccent),
            ),
          ),
        );
      },
    );
  }

  Widget _playerCard({
    required String name,
    required String tag,
    required int points,
    required bool isWinner,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          if (isWinner)
            const BoxShadow(color: Colors.amberAccent, blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          if (isWinner) const Icon(Icons.star, color: Colors.amber, size: 30),
          const SizedBox(height: 5),
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 30,
            child: Text(
              tag,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 25),
          Text(
            "$points",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: color,
            ),
          ),
          const Text(
            "POINTS",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate back to Home and clear the stack
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
            ),
            child: const Text(
              "PLAY AGAIN",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            child: const Text(
              "EXIT TO DASHBOARD",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
