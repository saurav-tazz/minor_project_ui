import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/matchroom.dart';

class QuestionSelectionScreen extends StatefulWidget {
  final List<String> genres;

  const QuestionSelectionScreen({super.key, required this.genres});

  @override
  State<QuestionSelectionScreen> createState() =>
      _QuestionSelectionScreenState();
}

class _QuestionSelectionScreenState extends State<QuestionSelectionScreen> {
  static const int maxSelection = 5;

  // Temporary mock questions (later: from backend)
  final List<Map<String, dynamic>> questions = [
    {
      "id": "q1",
      "text": "What is the capital of France?",
      "difficulty": "Easy",
    },
    {
      "id": "q2",
      "text": "Which planet is known as the Red Planet?",
      "difficulty": "Easy",
    },
    {
      "id": "q3",
      "text": "What is the chemical symbol for gold?",
      "difficulty": "Medium",
    },
    {
      "id": "q4",
      "text": "In which year did World War II end?",
      "difficulty": "Medium",
    },
    {"id": "q5", "text": "Who painted the Mona Lisa?", "difficulty": "Easy"},
    {
      "id": "q6",
      "text": "What is the largest ocean on Earth?",
      "difficulty": "Easy",
    },
    {
      "id": "q7",
      "text": "What gas do plants absorb from the atmosphere?",
      "difficulty": "Easy",
    },
    {
      "id": "q8",
      "text": "Who developed the theory of relativity?",
      "difficulty": "Hard",
    },
    {
      "id": "q9",
      "text": "What is the square root of 256?",
      "difficulty": "Easy",
    },
    {
      "id": "q10",
      "text": "Which country hosted the 2016 Olympics?",
      "difficulty": "Medium",
    },
  ];

  final Set<String> selectedIds = {};

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        if (selectedIds.length < maxSelection) {
          selectedIds.add(id);
        }
      }
    });
  }

  void submitSelection() {
    final selectedQuestions = questions
        .where((q) => selectedIds.contains(q["id"]))
        .toList();

    // ================= BACKEND INTEGRATION (FUTURE) =================
    // socket.emit("submitSelectedQuestions", {
    //   matchId: currentMatchId,
    //   userId: currentUserId,
    //   questions: selectedQuestions.map((q) => q["id"]).toList(),
    // });

    // OR REST API:
    // await http.post(
    //   Uri.parse("http://your-server/submit-questions"),
    //   body: jsonEncode({
    //     "matchId": currentMatchId,
    //     "userId": currentUserId,
    //     "questions": selectedQuestions.map((q) => q["id"]).toList(),
    //   }),
    // );

    // For now:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MatchRoomScreen(genres: widget.genres)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxSelection - selectedIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFF00A9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Select Questions"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Header
          const Text(
            "Choose 5 questions for your opponent",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 12),

          // Counter
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Selected: ${selectedIds.length}/$maxSelection",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      remaining == 0 ? "Done" : "Select $remaining more",
                      style: const TextStyle(color: Colors.yellow),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: selectedIds.length / maxSelection,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Question List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final isSelected = selectedIds.contains(q["id"]);

                return GestureDetector(
                  onTap: () => toggleSelection(q["id"]),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q["text"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Question ${index + 1}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedIds.length == maxSelection
                    ? submitSelection
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.white30,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  selectedIds.length == maxSelection
                      ? "Submit Questions"
                      : "Select $remaining More Questions",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
