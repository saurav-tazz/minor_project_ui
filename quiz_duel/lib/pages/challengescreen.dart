import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiz_duel/services/socket_service.dart';

class ChallengeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChallengeScreen({super.key, required this.userData});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  String? _roomCode;
  bool _isCreating = true;
  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _createRoom();
  }

  void _setupSocketListeners() {
    // Server confirmed room creation
    SocketService.instance.socket?.on('room_created', (data) {
      if (!mounted) return;
      setState(() {
        _roomCode = data['code'];
        _isCreating = false;
      });
      _startCountdown();
    });

    // Friend joined — navigate to question selection
    SocketService.instance.socket?.on('start_selection', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();

      final bool amIP1 =
          data['p1']['id'] == widget.userData['_id']?.toString() ||
          data['p1']['id'] == widget.userData['userId']?.toString();
      final myInventory = amIP1
          ? data['p1']['inventory']
          : data['p2']['inventory'];
      final opponentName = amIP1 ? data['p2']['name'] : data['p1']['name'];
      final innerUserData = Map<String, dynamic>.from(
        widget.userData['userData'] ?? widget.userData,
      );
      Navigator.pushReplacementNamed(
        context,
        '/questionSelection',
        arguments: {
          'roomId': data['roomId'],
          'userId':
              widget.userData['_id']?.toString() ??
              widget.userData['userId']?.toString(),
          'inventory': myInventory,
          'timer': data['timer'],
          'opponentName': opponentName,
          'amIP1': amIP1,
          'userData': {
            ...innerUserData,
            '_id':
                widget.userData['_id']?.toString() ??
                widget.userData['userId']?.toString(),
            'username': innerUserData['username'] ?? innerUserData['name'],
          },
        },
      );
    });

    // Room expired (60s timeout, no one joined)
    SocketService.instance.socket?.on('room_expired', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      _showExpiredDialog();
    });

    // Generic error
    SocketService.instance.socket?.on('error', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Something went wrong.')),
      );
      Navigator.pop(context);
    });
  }

  void _createRoom() {
    print("USER DATA: ${widget.userData}");
    print("USER ID SENT: ${widget.userData['userId']}");
    SocketService.instance.socket?.emit('create_room', {
      'userId':
          widget.userData['_id']?.toString() ??
          widget.userData['userId']
              ?.toString(), // Try both keys for compatibility
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelRoom() {
    if (_roomCode != null) {
      SocketService.instance.socket?.emit('cancel_room', {'code': _roomCode});
    }
    Navigator.pop(context);
  }

  void _copyCode() {
    if (_roomCode == null) return;
    Clipboard.setData(ClipboardData(text: _roomCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Room Expired'),
        content: const Text(
          'No one joined in time. Create a new room and try again.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SocketService.instance.socket?.off('room_created');
    SocketService.instance.socket?.off('start_selection');
    SocketService.instance.socket?.off('room_expired');
    SocketService.instance.socket?.off('error');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _cancelRoom,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.group, color: Colors.white, size: 26),
                    const SizedBox(width: 8),
                    const Text(
                      'Challenge a Friend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _isCreating
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF1E88E5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Creating room...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1E88E5,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_open_rounded,
                                  color: Color(0xFF1E88E5),
                                  size: 42,
                                ),
                              ),

                              const SizedBox(height: 24),

                              const Text(
                                'Your Room Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Code display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1E88E5,
                                    ).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  _roomCode ?? '------',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Copy button
                              TextButton.icon(
                                onPressed: _copyCode,
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: Color(0xFF1E88E5),
                                ),
                                label: const Text(
                                  'Copy Code',
                                  style: TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              const Text(
                                'Share this code with your friend.\nWaiting for them to join...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Countdown ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: _countdown / 60,
                                      strokeWidth: 5,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _countdown > 20
                                            ? const Color(0xFF1E88E5)
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_countdown',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Text(
                                        'sec',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Cancel
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _cancelRoom,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
