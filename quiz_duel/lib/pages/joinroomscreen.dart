// join_room_screen.dart
import 'package:flutter/material.dart';
import 'package:quiz_duel/services/socket_service.dart';

class JoinRoomScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const JoinRoomScreen({super.key, required this.userData});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Match started — go to question selection
    SocketService.instance.socket?.on('start_selection', (data) {
      if (!mounted) return;
      setState(() => _isJoining = false);

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

    // Error (invalid code, banned, etc.)
    SocketService.instance.socket?.on('error', (data) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Could not join room.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _joinRoom() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-character code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    SocketService.instance.socket?.emit('join_room', {
      'userId':
          widget.userData['_id']?.toString() ??
          widget.userData['userId']?.toString(),
      'code': code,
    });

    // Timeout guard — if no response in 8s, unblock UI
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isJoining) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No response from server. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    SocketService.instance.socket?.off('start_selection');
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Join a Room',
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
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.vpn_key_rounded,
                            color: Color(0xFF1E88E5),
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Enter Room Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Ask your friend for their 6-character code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),

                        const SizedBox(height: 32),

                        // Code input
                        TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: Color(0xFF1E88E5),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '······',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              letterSpacing: 8,
                              color: Colors.grey.shade300,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                          ),
                          onChanged: (v) {
                            // Auto-uppercase as user types
                            final upper = v.toUpperCase();
                            if (v != upper) {
                              _codeController.value = _codeController.value
                                  .copyWith(
                                    text: upper,
                                    selection: TextSelection.collapsed(
                                      offset: upper.length,
                                    ),
                                  );
                            }
                          },
                          onSubmitted: (_) => _joinRoom(),
                        ),

                        const SizedBox(height: 32),

                        // Join button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _joinRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Join Room',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
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
