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
    this.userData = const {},
  });

  @override
  State<MatchRoomScreen> createState() => _MatchRoomScreenState();
}

class _MatchRoomScreenState extends State<MatchRoomScreen> {
  int currentIndex = 0;
  int score = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int timeLeft = 50;
  Timer? _timer;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();

    widget.socket.on('game_over', (data) {
      if (mounted) {
        final args = Map<String, dynamic>.from(data);
        args['myId'] = widget.userId;
        args['userData'] = widget.userData;
        Navigator.pushReplacementNamed(
          context,
          '/resultscreen',
          arguments: args,
        );
      }
    });

    widget.socket.on('opponent_left', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opponent disconnected. Finish your questions to see the result!',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    widget.socket.on('opponent_forfeited', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opponent forfeited. Finish your questions to see the result!',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      timeLeft = 50;
      answered = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _timer?.cancel();
        widget.socket.emit('submit_score', {
          'roomId': widget.roomId,
          'userId': widget.userId,
          'score': {'correct': correctCount, 'wrong': wrongCount},
        });
      }
    });
  }

  void _handleAnswer(int selectedIndex) {
    if (answered) return;

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

    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
      });
    } else {
      _timer?.cancel();
      widget.socket.emit('submit_score', {
        'roomId': widget.roomId,
        'userId': widget.userId,
        'score': {'correct': correctCount, 'wrong': wrongCount},
      });
    }
  }

  Color get _timerBarColor {
    if (timeLeft > 30) return Colors.greenAccent;
    if (timeLeft > 15) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.socket.off('game_over');
    widget.socket.off('opponent_left');
    widget.socket.off('opponent_forfeited');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Navigator.pushReplacementNamed(
                    context,
                    '/resultscreen',
                    arguments: {
                      'results': [
                        {
                          'userId': 'test_user',
                          'name': 'You (Tester)',
                          'matchScore': 80,
                        },
                        {
                          'userId': 'bot_123',
                          'name': 'Opponent',
                          'matchScore': 50,
                        },
                      ],
                      'winner': 'test_user',
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

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Match?'),
            content: const Text(
              'Leaving will be counted as a loss. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );

        if (shouldLeave == true) {
          widget.socket.emit('forfeit', {
            'userId': widget.userId,
            'roomId': widget.roomId,
          });
          return true;
        }
        return false;
      },
      child: Scaffold(
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
                  /// 🔹 Timer Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${currentIndex + 1} of ${widget.questions.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${timeLeft}s',
                            style: TextStyle(
                              color: timeLeft <= 10
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: timeLeft / 50,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _timerBarColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      question['questionText'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 Options
                  /// 🔹 Options
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: question['options'].length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 10),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
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

                  const Spacer(),

                  /// 🔹 Bottom Progress Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / widget.questions.length,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
