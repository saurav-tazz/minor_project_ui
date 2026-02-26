import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:quiz_duel/pages/matchroom.dart'; // Ensure this matches your gameplay file name

class QuestionSelectionScreen extends StatefulWidget {
  final List<dynamic> inventory;
  final String roomId;
  final String userId;
  final dynamic socket;
  final List<String> genres;

  const QuestionSelectionScreen({
    super.key,
    required this.inventory,
    required this.roomId,
    required this.userId,
    required this.socket,
    required this.genres,
  });

  @override
  State<QuestionSelectionScreen> createState() =>
      _QuestionSelectionScreenState();
}

class _QuestionSelectionScreenState extends State<QuestionSelectionScreen> {
  static const int maxSelection = 5;
  final Set<String> selectedIds = {};
  int _timeLeft = 20;
  Timer? _timer;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    startTimer();

    // 🔹 LISTENER: Move to Battle when BOTH players are ready
    widget.socket.on('start_duel', (data) {
      if (mounted) {
        _timer?.cancel();

        // Remove waiting overlay if it's currently showing
        if (isSubmitted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Logic: You play the 5 questions your opponent picked for you
        bool isPlayerOne = widget.userId == data['p1UserId'];
        List<dynamic> myQuestions = isPlayerOne
            ? data['p1Questions']
            : data['p2Questions'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PlayScreen(
              questions: myQuestions,
              roomId: widget.roomId,
              userId: widget.userId,
              socket: widget.socket,
            ),
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
        if (!isSubmitted) autoSubmit();
      }
    });
  }

  void toggleSelection(String id) {
    if (isSubmitted) return;
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else if (selectedIds.length < maxSelection) {
        selectedIds.add(id);
      }
    });
  }

  void autoSubmit() {
    final random = Random();
    List<String> availableIds = widget.inventory
        .map((q) => q['_id'].toString())
        .where((id) => !selectedIds.contains(id))
        .toList();

    while (selectedIds.length < maxSelection && availableIds.isNotEmpty) {
      final randomIndex = random.nextInt(availableIds.length);
      selectedIds.add(availableIds[randomIndex]);
      availableIds.removeAt(randomIndex);
    }
    submitSelection();
  }

  void submitSelection() {
    if (isSubmitted) return;
    setState(() => isSubmitted = true);
    _timer?.cancel();

    widget.socket.emit('submit_selection', {
      'roomId': widget.roomId,
      'userId': widget.userId,
      'selectedIds': selectedIds.toList(),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 20),
                  Text(
                    "Selection Locked!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Waiting for opponent...",
                    style: TextStyle(color: Colors.grey),
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
    widget.socket.off('start_duel');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxSelection - selectedIds.length;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF00A9FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "STRATEGY: $_timeLeft s",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Pick 5 questions to send to your opponent!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildSelectionProgress(remaining),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.inventory.length,
                itemBuilder: (context, index) {
                  final q = widget.inventory[index];
                  final String qId = q['_id'].toString();
                  final isSelected = selectedIds.contains(qId);

                  return GestureDetector(
                    onTap: () => toggleSelection(qId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Row(
                        children: [
                          _difficultyBadge(q['difficulty'] ?? 'easy'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q['questionText'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionProgress(int remaining) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected: ${selectedIds.length}/$maxSelection",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                remaining == 0 ? "Ready!" : "Pick $remaining more",
                style: TextStyle(
                  color: remaining == 0
                      ? Colors.greenAccent
                      : Colors.yellowAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: selectedIds.length / maxSelection,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    bool canSubmit = selectedIds.length == maxSelection;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: canSubmit ? submitSelection : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          disabledBackgroundColor: Colors.white24,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "SEND TO OPPONENT",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _difficultyBadge(String diff) {
    Color color = diff.toLowerCase() == 'hard'
        ? Colors.red
        : (diff.toLowerCase() == 'medium' ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        diff.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
