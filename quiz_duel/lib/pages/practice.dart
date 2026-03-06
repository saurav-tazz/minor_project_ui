import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_duel/pages/homescreen.dart';

class PracticeScreen extends StatefulWidget {
  final List<int> genres;
  final Map<String, dynamic> userData;

  const PracticeScreen({
    super.key,
    required this.genres,
    required this.userData,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // ── State ──────────────────────────────────────────────
  List<dynamic> questions = [];
  bool isLoading = true;
  String? errorMessage;

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int timeLeft = 10;
  bool answered = false;
  bool showResult = false;
  int? selectedAnswer;

  Timer? _timer;

  static const int totalQuestions =
      10; // change this number to adjust question count

  // ── Lifecycle ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Data Fetching ──────────────────────────────────────
  Future<void> _fetchQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final genreString = widget.genres.join(',');
      final response = await http.get(
        Uri.parse(
          'https://quiz-royale-ash0.onrender.com/api/questions/practice?genres=$genreString&limit=$totalQuestions',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = data['questions'];
          isLoading = false;
          currentIndex = 0;
          correctCount = 0;
          wrongCount = 0;
          answered = false;
          showResult = false;
          selectedAnswer = null;
        });
        _startTimer();
      } else {
        setState(() {
          errorMessage = "Failed to load questions. Try again.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error. Try again.";
        isLoading = false;
      });
    }
  }

  // ── Timer ──────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      timeLeft = 10;
      answered = false;
      selectedAnswer = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    setState(() {
      answered = true;
      wrongCount++;
    });
    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  // ── Answer Handling ────────────────────────────────────
  void _handleAnswer(int selectedIndex) {
    if (answered) return;
    _timer?.cancel();

    final currentQuestion = questions[currentIndex];
    final isCorrect = selectedIndex == currentQuestion['correctAnswer'];

    setState(() {
      answered = true;
      selectedAnswer = selectedIndex;
      if (isCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }
    });

    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => showResult = true);
    }
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (errorMessage != null) return _buildError();
    if (showResult) return _buildResult();
    return _buildQuestion();
  }

  // ── Loading Screen ─────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Loading questions...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error Screen ───────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 60),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Question Screen ────────────────────────────────────
  Widget _buildQuestion() {
    final question = questions[currentIndex];
    final correctAnswer = question['correctAnswer'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            userData: widget.userData,
                            genres: widget.genres,
                          ),
                        ),
                        (route) => false,
                      ),
                    ),
                    Text(
                      "Question ${currentIndex + 1}/$totalQuestions",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Timer circle
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: timeLeft <= 3
                            ? Colors.red.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${timeLeft}s",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / totalQuestions,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Score chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScoreChip(
                      Icons.check_circle,
                      "$correctCount Correct",
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildScoreChip(
                      Icons.cancel,
                      "$wrongCount Wrong",
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    question['questionText'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: question['options'].length,
                    itemBuilder: (context, i) {
                      Color bgColor = Colors.white;
                      if (answered) {
                        if (i == correctAnswer) {
                          bgColor = Colors.green.shade100;
                        } else if (i == selectedAnswer && i != correctAnswer) {
                          bgColor = Colors.red.shade100;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bgColor,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: answered ? null : () => _handleAnswer(i),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "${String.fromCharCode(65 + i)}. ${question['options'][i]}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result Screen ──────────────────────────────────────
  Widget _buildResult() {
    final int score = (correctCount * 10) - (wrongCount * 5);
    final double percent = (correctCount / totalQuestions) * 100;

    String grade;
    Color gradeColor;
    IconData gradeIcon;

    if (percent >= 80) {
      grade = "Excellent!";
      gradeColor = Colors.green;
      gradeIcon = Icons.emoji_events;
    } else if (percent >= 50) {
      grade = "Good Job!";
      gradeColor = Colors.orange;
      gradeIcon = Icons.thumb_up;
    } else {
      grade = "Keep Practicing!";
      gradeColor = Colors.red;
      gradeIcon = Icons.fitness_center;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(gradeIcon, color: gradeColor, size: 80),
                const SizedBox(height: 16),
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
                const SizedBox(height: 30),

                // Score card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$score pts",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildResultStat(
                            "Correct",
                            correctCount,
                            Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildResultStat("Wrong", wrongCount, Colors.red),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildResultStat(
                            "Total",
                            totalQuestions,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Play Again
                ElevatedButton(
                  onPressed: _fetchQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E88E5),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "PLAY AGAIN",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to Home
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userData: widget.userData,
                        genres: widget.genres,
                      ),
                    ),
                    (route) => false,
                  ),
                  child: const Text(
                    "BACK TO HOME",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  Widget _buildResultStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
