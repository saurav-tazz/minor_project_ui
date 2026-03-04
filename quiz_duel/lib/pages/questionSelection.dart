import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class QuestionSelectionScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final List<dynamic> inventory;
  final int timer;
  final IO.Socket socket;
  final bool amIP1;
  final Map<String, dynamic> userData;

  const QuestionSelectionScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.inventory,
    required this.timer,
    required this.socket,
    required this.amIP1,
    this.userData = const {},
  });

  @override
  State<QuestionSelectionScreen> createState() =>
      _QuestionSelectionScreenState();
}

class _QuestionSelectionScreenState extends State<QuestionSelectionScreen> {
  List<String> selectedIds = [];
  late int timeLeft;
  Timer? _timer;
  bool _isWaiting = false; // To show waiting state after submission

  @override
  void initState() {
    super.initState();
    timeLeft = widget.timer;
    _startTimer();

    // Listen for the server to confirm both players are ready to start the match
    widget.socket.on('start_duel', (data) {
      if (mounted) {
        _timer?.cancel();

        // Debug — remove after confirming fix
        print('start_duel received keys: ${data.keys.toList()}');
        print('amIP1: ${widget.amIP1}');
        print('p1Questions count: ${data['p1Questions']?.length}');
        print('p2Questions count: ${data['p2Questions']?.length}');

        final rawQuestions = widget.amIP1
            ? data['p1Questions']
            : data['p2Questions'];

        // Safely cast to List<dynamic>, fallback to empty list
        final myQuestions = rawQuestions != null
            ? List<dynamic>.from(rawQuestions)
            : <dynamic>[];

        print('myQuestions going to matchroom: ${myQuestions.length}');

        Navigator.pushReplacementNamed(
          context,
          '/matchroom',
          arguments: {
            'roomId': widget.roomId,
            'userId': widget.userId,
            'questions': myQuestions,
            'userData': widget.userData,
          },
        );
      }
    });
  }

  // 3/3/2026--autosubmit if time runs out before user selects 5 questions. Fills remaining slots with random inventory items.
  // void _startTimer() {
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (timeLeft > 0) {
  //       setState(() => timeLeft--);
  //     } else {
  //       _submitSelection();
  //     }
  //   });
  // }
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _timer?.cancel();
        // IF THE USER SELECTED SOME BUT NOT ALL, AUTO-FILL AND SUBMIT
        if (selectedIds.length < 5) {
          // Fill remaining slots from inventory
          for (var item in widget.inventory) {
            if (selectedIds.length >= 5) break;
            if (!selectedIds.contains(item['_id'].toString())) {
              selectedIds.add(item['_id'].toString());
            }
          }
        }
        _submitSelection(); // Send whatever we have (now 5) to the server
      }
    });
  }

  void _submitSelection() {
    _timer?.cancel();
    // Integration with backend: matches the 'submit_selection' event [cite: 314]
    widget.socket.emit('submit_selection', {
      'roomId': widget.roomId,
      'userId': widget.userId,
      'selectedIds': selectedIds,
    });
    // Wait for start_duel socket event — navigation happens there
    setState(() => _isWaiting = true);

    //temporary navigation to matchroom for testing without backend
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (mounted) {
    //     Navigator.pushReplacementNamed(
    //       context,
    //       '/matchroom',
    //       arguments: {
    //         'roomId': widget.roomId,
    //         'userId': widget.userId,
    //         'questions': widget.inventory
    //             .take(5)
    //             .toList(), // Just take the first 5 from inventory as dummy data
    //       },
    //     );
    //   }
    // });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A3FF), // Match UI Blue
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSelectionProgress(),
            Expanded(child: _buildQuestionList()),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb, color: Colors.yellow, size: 30),
              const SizedBox(width: 10),
              const Text(
                "Select Questions",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Text(
            "Choose 5 questions for your opponent",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionProgress() {
    double progress = selectedIds.length / 5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected: ${selectedIds.length}/5",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "⏳ ${timeLeft}s",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.inventory.length,
      itemBuilder: (context, index) {
        final q = widget.inventory[index];
        final id = q['_id'].toString();
        final isSelected = selectedIds.contains(id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedIds.remove(id);
              } else if (selectedIds.length < 5) {
                selectedIds.add(id);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: Colors.yellow, width: 3)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['questionText'] ?? "No text",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Difficulty: ${q['difficulty'] ?? 'Easy'}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    bool canSubmit = selectedIds.length == 5;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Colors.yellow : Colors.white24,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: (canSubmit && !_isWaiting) ? _submitSelection : null,
        child: _isWaiting
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                canSubmit
                    ? "Confirm Selections"
                    : "Select ${5 - selectedIds.length} More Questions",
              ),
      ),
    );
  }
}
