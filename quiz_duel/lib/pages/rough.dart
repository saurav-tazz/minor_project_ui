import 'package:flutter/material.dart';

class QuestionSelectionScreen extends StatefulWidget {
  final List<String> questions;
  const QuestionSelectionScreen({required this.questions});

  @override
  _QuestionSelectionScreenState createState() => _QuestionSelectionScreenState();
}

class _QuestionSelectionScreenState extends State<QuestionSelectionScreen> {
  final Set<int> selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select 5 Questions")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(widget.questions[index]),
                  value: selectedIndexes.contains(index),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && selectedIndexes.length < 5) {
                        selectedIndexes.add(index);
                      } else {
                        selectedIndexes.remove(index);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Text("Selected: ${selectedIndexes.length}/5"),
          ElevatedButton(
            onPressed: selectedIndexes.length == 5
                ? () {
              final selectedQuestions = selectedIndexes
                  .map((i) => widget.questions[i])
                  .toList();
              // Send to server
              // socket.emit("questionsSelected", { "matchId": matchId, "questions": selectedQuestions });
            }
                : null,
            child: Text("Confirm Selection"),
          ),
        ],
      ),
    );
  }
}