import 'package:flutter/material.dart';
import 'dart:async';
import 'package:quiz_duel/pages/resultscreen.dart';

class PlayScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String roomId;
  final String userId;
  final dynamic socket;
  final List<String>? genres;

  const PlayScreen({
    super.key,
    required this.questions,
    required this.roomId,
    required this.userId,
    required this.socket,
    this.genres,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int currentQuestionIndex = 0;
  int playerScore = 0;
  int wrongAnswers = 0;
  bool answered = false;
  String? selectedAnswer;

  int _timeLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();

    // 🔹 LISTENER: Handle Game Over (triggered when both players submit scores)
    widget.socket.on('game_over', (data) {
      if (mounted) {
        _timer?.cancel();

        // Ensure any open dialogs are closed before navigating to results
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst == false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResultScreen(gameResults: data, socket: widget.socket),
          ),
        );
      }
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        submitFinalScore();
      }
    });
  }

  void checkAnswer(String selected) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedAnswer = selected;

      if (selected == widget.questions[currentQuestionIndex]["correctAnswer"]) {
        playerScore++;
      } else {
        wrongAnswers++;
      }
    });

    // Short delay so the player can see the correct/incorrect feedback colors
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (currentQuestionIndex < widget.questions.length - 1) {
        if (mounted) {
          setState(() {
            currentQuestionIndex++;
            answered = false;
            selectedAnswer = null;
          });
        }
      } else {
        submitFinalScore();
      }
    });
  }

  void submitFinalScore() {
    if (_timer != null && _timer!.isActive) _timer!.cancel();

    widget.socket.emit('submit_score', {
      'roomId': widget.roomId,
      'userId': widget.userId,
      'score': {
        'correct': playerScore,
        'wrong': wrongAnswers,
        'timeLeft': _timeLeft,
      },
    });

    _showWaitingOverlay();
  }

  void _showWaitingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "BATTLE ENDED",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Waiting for opponent...",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Divider(height: 30),
                  Text(
                    "Your Correct Answers: $playerScore",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  @override
  void dispose() {
    _timer?.cancel();
    widget.socket.off('game_over');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = widget.questions[currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async => false, // Prevent users from leaving mid-game
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 🔹 Match Status Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip(
                        Icons.timer,
                        "$_timeLeft s",
                        _timeLeft < 10 ? Colors.red : Colors.orange,
                      ),
                      _statusChip(
                        Icons.emoji_events,
                        "$playerScore",
                        Colors.amber,
                      ),
                      _statusChip(
                        Icons.quiz,
                        "${currentQuestionIndex + 1}/${widget.questions.length}",
                        Colors.blue,
                      ),
                    ],
                  ),
                ),

                // 🔹 Question Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value:
                          (currentQuestionIndex + 1) / widget.questions.length,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ),

                const Spacer(),

                // 🔹 Question Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    question["questionText"] ?? "Question loading...",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // 🔹 Options List
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    children: (question["options"] as List).map((opt) {
                      final optionText = opt.toString();
                      final isCorrect = optionText == question["correctAnswer"];
                      final isSelected = selectedAnswer == optionText;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ElevatedButton(
                          onPressed: answered
                              ? null
                              : () => checkAnswer(optionText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: answered
                                ? (isCorrect
                                      ? Colors.greenAccent.shade700
                                      : (isSelected
                                            ? Colors.redAccent
                                            : Colors.white.withOpacity(0.9)))
                                : Colors.white,
                            disabledBackgroundColor: isCorrect
                                ? Colors.greenAccent.shade700
                                : (isSelected
                                      ? Colors.redAccent
                                      : Colors.white24),
                            foregroundColor:
                                (answered && (isSelected || isCorrect))
                                ? Colors.white
                                : Colors.blue.shade900,
                            minimumSize: const Size(double.infinity, 65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: isSelected ? 0 : 5,
                          ),
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: (isSelected || isCorrect)
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: (answered && (isSelected || isCorrect))
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
