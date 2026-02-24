import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/homescreen.dart';
import 'package:quiz_duel/pages/resultscreen.dart';

class MatchRoomScreen extends StatefulWidget {
  final List<String> genres;

  const MatchRoomScreen({super.key, required this.genres});


  @override
  State<MatchRoomScreen> createState() => _MatchRoomScreenState();
}

class _MatchRoomScreenState extends State<MatchRoomScreen> {
  int currentQuestionIndex = 0;
  int playerScore = 0;
  bool answered = false;
  String? selectedAnswers;


  // Example question bank with genre tags
  final allQuestions = [
    {
      "genre": "Geography",
      "question": "What is the capital of Nepal?",
      "options": ["Kathmandu", "Pokhara", "Bhaktapur", "Mustang"],
      "answer": "Kathmandu"
    },
    {
      "genre": "Science",
      "question": "What is the chemical symbol for water?",
      "options": ["H2O", "O2", "CO2", "NaCl"],
      "answer": "H2O"
    },
    {
      "genre": "History",
      "question": "Who discovered gravity?",
      "options": ["Einstein", "Newton", "Galileo", "Tesla"],
      "answer": "Newton"
    },
  ];

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    // Filter questions by selected genres
    questions = allQuestions
        .where((q) => widget.genres.contains(q["genre"]))
        .toList();

    if (questions.isEmpty) {
      questions = [
        {
          "question": "No questions available for selected genres.",
          "options": ["OK"],
          "answer": "OK"
        }
      ];
    }
  }

  void checkAnswer(String selected) {
    setState(() {
      answered = true;
      selectedAnswers = selected;
      if (selected == questions[currentQuestionIndex]["answer"]) {
        playerScore++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          answered = false;
          selectedAnswers = null;
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Match finished! Final score: $playerScore")),
        // );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: playerScore,
              totalQuestions: questions.length,
              genres: widget.genres,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];


    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        title: const Text("Match Room",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => HomeScreen(genres: widget.genres),
                )
            );
          },
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Genres: ${widget.genres.join(', ')}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Score: $playerScore",
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Question Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          question["question"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (currentQuestionIndex + 1) / questions.length,
                          backgroundColor: Colors.grey.shade300,
                          color: const Color(0xFF1E88E5),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Answer Options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: (question["options"] as List<String>).map((opt) {
                      final isCorrect = opt == question["answer"];
                      final isSelected = selectedAnswers == opt;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: (){
                            if(!answered) {
                              checkAnswer(opt);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (answered && isSelected)
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Colors.white,
                            foregroundColor: (answered && isSelected)
                                ? Colors.white
                                : const Color(0xFF1E88E5),
                            minimumSize: const Size(double.infinity, 60),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}