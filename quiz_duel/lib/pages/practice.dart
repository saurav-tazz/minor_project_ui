import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_duel/pages/homescreen.dart';
import 'package:quiz_duel/services/constants.dart';

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

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
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

  // Animations
  late AnimationController _questionCtrl;
  late AnimationController _feedbackCtrl;
  Color _feedbackColor = Colors.transparent;

  static const int totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _questionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final genreString = widget.genres.join(',');
      final response = await http.get(
        Uri.parse(
          '${AppConstants.apiUrl}/questions/practice?genres=$genreString&limit=$totalQuestions',
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
        _questionCtrl.forward(from: 0);
        _startTimer();
      } else {
        setState(() {
          errorMessage = 'Failed to load questions.';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = 'Connection error. Try again.';
        isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      timeLeft = 10;
      answered = false;
      selectedAnswer = null;
    });
    _questionCtrl.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    _flashFeedback(false);
    setState(() {
      answered = true;
      wrongCount++;
    });
    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  void _handleAnswer(int idx) {
    if (answered) return;
    _timer?.cancel();
    final isCorrect = idx == questions[currentIndex]['correctAnswer'];
    _flashFeedback(isCorrect);
    setState(() {
      answered = true;
      selectedAnswer = idx;
      if (isCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }
    });
    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  void _flashFeedback(bool correct) {
    _feedbackColor = correct
        ? Colors.green.withOpacity(0.18)
        : Colors.red.withOpacity(0.18);
    _feedbackCtrl.forward(from: 0).then((_) => _feedbackCtrl.reverse());
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (errorMessage != null) return _buildError();
    if (showResult) return _buildResult();
    return _buildQuestion();
  }

  Widget _buildLoading() => Scaffold(
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
              'Loading questions...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildError() => Scaffold(
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
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildQuestion() {
    final q = questions[currentIndex];
    final correctAnswer = q['correctAnswer'];
    // Timer color: green → orange → red
    final timerColor = timeLeft > 6
        ? const Color(0xFF1E88E5)
        : timeLeft > 3
        ? Colors.orange
        : Colors.red;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Feedback flash overlay
          AnimatedBuilder(
            animation: _feedbackCtrl,
            builder: (_, __) => Container(
              color: _feedbackColor.withOpacity(_feedbackCtrl.value),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header row
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
                          (r) => false,
                        ),
                      ),
                      Text(
                        'Question ${currentIndex + 1}/$totalQuestions',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Animated timer circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: timerColor.withOpacity(0.7),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${timeLeft}s',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: timeLeft <= 3 ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: currentIndex / totalQuestions,
                      end: (currentIndex + 1) / totalQuestions,
                    ),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreChip(
                        Icons.check_circle,
                        '$correctCount Correct',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _scoreChip(Icons.cancel, '$wrongCount Wrong', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Question card with slide-in
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _questionCtrl,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: FadeTransition(
                      opacity: _questionCtrl,
                      child: Container(
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
                          q['questionText'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  Expanded(
                    child: ListView.builder(
                      itemCount: q['options'].length,
                      itemBuilder: (_, i) {
                        Color bg = Colors.white;
                        Color fg = Colors.black87;
                        if (answered) {
                          if (i == correctAnswer) {
                            bg = Colors.green.shade100;
                            fg = Colors.green.shade800;
                          } else if (i == selectedAnswer) {
                            bg = Colors.red.shade100;
                            fg = Colors.red.shade800;
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionButton(
                            label:
                                '${String.fromCharCode(65 + i)}. ${q['options'][i]}',
                            bgColor: bg,
                            fgColor: fg,
                            onTap: answered ? null : () => _handleAnswer(i),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(IconData icon, String label, Color color) => Container(
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

  Widget _buildResult() {
    final score = (correctCount * 10) - (wrongCount * 5);
    final percent = correctCount / totalQuestions * 100;
    final grade = percent >= 80
        ? 'Excellent!'
        : percent >= 50
        ? 'Good Job!'
        : 'Keep Practicing!';
    final gradeColor = percent >= 80
        ? Colors.green
        : percent >= 50
        ? Colors.orange
        : Colors.red;
    final gradeIcon = percent >= 80
        ? Icons.emoji_events
        : percent >= 50
        ? Icons.thumb_up
        : Icons.fitness_center;

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - v)),
            child: child,
          ),
        ),
        child: Container(
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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (_, v, __) => Transform.scale(
                      scale: v,
                      child: Icon(gradeIcon, color: gradeColor, size: 80),
                    ),
                  ),
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
                          '$score pts',
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
                            _resultStat('Correct', correctCount, Colors.green),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _resultStat('Wrong', wrongCount, Colors.red),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _resultStat('Total', totalQuestions, Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
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
                      'PLAY AGAIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          userData: widget.userData,
                          genres: widget.genres,
                        ),
                      ),
                      (r) => false,
                    ),
                    child: const Text(
                      'BACK TO HOME',
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
      ),
    );
  }

  Widget _resultStat(String label, int value, Color color) => Column(
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

/// Pressable option button with scale effect
class _OptionButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback? onTap;
  const _OptionButton({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.reverse() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.forward();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              color: widget.fgColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
