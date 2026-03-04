import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:quiz_duel/pages/questionSelection.dart';
import 'package:quiz_duel/services/socket_service.dart';
// import 'package:quiz_duel/pages/homescreen.dart';

class LoadingScreen extends StatefulWidget {
  final String userId;
  final List<int> genres;
  final Map<String, dynamic> userData;

  const LoadingScreen({
    super.key,
    required this.userId,
    required this.genres,
    required this.userData,
  });

  @override
  // ignore: library_private_types_in_public_api
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double progress = 0;
  Timer? _timer;
  Timer? _fallbackTimer;
  String opponentName = "?";

  @override
  void initState() {
    super.initState();

    // Start matchmaking
    SocketService.instance.socket?.emit('join_match', {
      'userId': widget.userId,
      'genres': widget.genres,
    });

    // Listen to matchmaking events
    SocketService.instance.socket?.on('waiting', (_) {
      _startProgress();
    });

    SocketService.instance.socket?.on('start_selection', (data) {
      _timer?.cancel();
      _fallbackTimer?.cancel();

      final roomId = data['roomId'];
      final timer = data['timer'];

      final bool amIP1 = data['p1']['id'] == widget.userId;

      final myInventory = amIP1
          ? data['p1']['inventory']
          : data['p2']['inventory'];
      final opponent = amIP1 ? data['p2']['name'] : data['p1']['name'];

      setState(() {
        opponentName = opponent;
      });

      Navigator.pushReplacementNamed(
        context,
        '/questionSelection',
        arguments: {
          'roomId': roomId,
          'userId': widget.userId,
          'inventory': myInventory,
          'timer': timer,
          'opponentName': opponent,
          'amIP1': amIP1,
          'selectionTimer': 30, // 30 seconds for draft phase
          'matchTimer': 60, // 60 seconds for the actual match
          'socket': SocketService.instance.socket,
          'userData': widget.userData,
        },
      );
    });

    SocketService.instance.socket?.on('error', (message) {
      _timer?.cancel();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $message")));
      Navigator.pop(context);
    });

    _fallbackTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        SocketService.instance.socket?.emit('cancel_match', {
          'userId': widget.userId,
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No opponent found. Please try again! 😔"),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(15),
          ),
        );
      }
    });
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        progress += 5;
        if (progress >= 100) progress = 99; // max before match found
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
    SocketService.instance.socket?.off('waiting');
    SocketService.instance.socket?.off('start_selection');
    SocketService.instance.socket?.off('error');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt,
                  size: 50,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Finding Your Opponent",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Found potential matches...",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlayerCircle("You", Colors.blue),
                    const CircularProgressIndicator(color: Colors.blue),
                    _buildPlayerCircle(opponentName, Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text("${progress.toInt()}%"),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tip: Answer quickly to earn bonus points!",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCircle(String name, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            name[0],
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}
