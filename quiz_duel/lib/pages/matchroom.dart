import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MatchRoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final List<dynamic> questions;
  final IO.Socket socket;
  final Map<String, dynamic> userData;

  const MatchRoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.questions,
    required this.socket,
    this.userData = const {}, // Optional user data for later use
  });

  @override
  State<MatchRoomScreen> createState() => _MatchRoomScreenState();
}

class _MatchRoomScreenState extends State<MatchRoomScreen> {
  int currentIndex = 0;
  int score = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int timeLeft = 10;
  Timer? _timer;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();

    widget.socket.on('game_over', (data) {
      if (mounted) {
        final args = Map<String, dynamic>.from(data);
        args['myId'] = widget.userId; // so ResultScreen knows who "me" is
        args['userData'] = widget.userData;
        Navigator.pushReplacementNamed(
          context,
          '/resultscreen',
          arguments: args,
        );
      }
    });
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      timeLeft = 10;
      answered = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _nextQuestion();
      }
    });
  }

  void _handleAnswer(int selectedIndex) {
    if (answered) return;
    _timer?.cancel();

    final currentQuestion = widget.questions[currentIndex];

    print("DEBUG question keys: ${currentQuestion.keys.toList()}");
    print("DEBUG correctAnswerIndex: ${currentQuestion['correctAnswer']}");
    print("DEBUG selectedIndex: $selectedIndex");

    final isCorrect = selectedIndex == currentQuestion['correctAnswer'];

    if (isCorrect) {
      score += 10;
      correctCount++;
    } else {
      wrongCount++;
    }

    setState(() => answered = true);

    // widget.socket.emit('submit_answer', {
    //   'roomId': widget.roomId,
    //   'userId': widget.userId,
    //   'questionIndex': currentIndex,
    //   'isCorrect': isCorrect,
    //   'points': isCorrect ? 10 : 0,
    // }); claude commented out for testing without socket connection

    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
      });
      _startQuestionTimer();
    } else {
      _timer?.cancel();

      print(
        "DEBUG: Sending Score - Correct: $correctCount, Wrong: $wrongCount",
      );

      widget.socket.emit('submit_score', {
        'roomId': widget.roomId,
        'userId': widget.userId,
        'score': {'correct': correctCount, 'wrong': wrongCount},
      });
    }

    // All questions done — send final score to backend- claude commented out for testing without socket connection
    // widget.socket.emit('submit_score', {
    //   'roomId': widget.roomId,
    //   'userId': widget.userId,
    //   'score': {'correct': correctCount, 'wrong': wrongCount},
    // });
    // Navigation now happens via the 'game_over' socket event in initState

    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (mounted) {
    //     Navigator.pushReplacementNamed(
    //       context,
    //       '/resultscreen', // Matches your main.dart onGenerateRoute name
    //       arguments: {
    //         'results': [
    //           {
    //             'userId': widget.userId,
    //             'name': 'You (Testing)',
    //             'matchScore': score,
    //           },
    //           {
    //             'userId': 'dummy_id',
    //             'name': 'Opponent',
    //             'matchScore': 30, // Dummy score for testing
    //           },
    //         ],
    //         'winner': score > 30 ? widget.userId : 'dummy_id',
    //       },
    //     );
    //   }
    // });claude commented out for testing without socket connection
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Stop listening to game_over before the widget is destroyed
    widget.socket.off('game_over');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.questions.isEmpty) {
    //   return const Scaffold(body: Center(child: Text("No questions found.")));
    // }
    if (widget.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No questions found (Testing Mode)"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 🚀 MANUALLY JUMP TO RESULTS
                  Navigator.pushReplacementNamed(
                    context,
                    '/resultscreen',
                    arguments: {
                      'results': [
                        {
                          'userId': 'test_user',
                          'name': 'You (Tester)',
                          'matchScore': 80, // Dummy score
                        },
                        {
                          'userId': 'bot_123',
                          'name': 'Opponent',
                          'matchScore': 50, // Dummy score
                        },
                      ],
                      'winner': 'test_user', // Sets you as winner for testing
                    },
                  );
                },
                child: const Text("View Result Screen"),
              ),
            ],
          ),
        ),
      );
    }

    final question = widget.questions[currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21A1F1), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 🔹 Top Scoreboard
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// You
                      // Column(
                      //   children: [
                      //     const Text(
                      //       "You",
                      //       style: TextStyle(color: Colors.white70),
                      //     ),
                      //     Text(
                      //       "$score pts",
                      //       style: const TextStyle(
                      //         color: Colors.white,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      /// Timer Circle
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${timeLeft}s",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      /// Opponent Placeholder
                      // Column(
                      //   children: const [
                      //     Text(
                      //       "Opponent",
                      //       style: TextStyle(color: Colors.white70),
                      //     ),
                      //     Text(
                      //       "0 pts",
                      //       style: TextStyle(
                      //         color: Colors.white,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔹 Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Question ${currentIndex + 1} of ${widget.questions.length}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question['questionText'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 Options
                Expanded(
                  child: ListView.builder(
                    itemCount: question['options'].length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _handleAnswer(i),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${String.fromCharCode(65 + i)}. ${question['options'][i]}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// 🔹 Bottom Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / widget.questions.length,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
