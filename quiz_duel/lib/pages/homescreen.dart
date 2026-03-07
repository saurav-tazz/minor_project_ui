import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  final List<int> genres;
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.genres, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late List<int> currentGenres;
  late Map<String, dynamic> currentUserData;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    currentGenres = widget.genres;
    currentUserData = widget.userData;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _listenForStatsUpdate();
  }

  void _listenForStatsUpdate() {
    SocketService.instance.socket?.on('stats_update', (data) {
      if (!mounted) return;
      setState(() {
        final updatedStats = {
          ...((currentUserData['stats'] as Map?) ?? {}),
          'totalPoints':
              data['points'] ?? currentUserData['stats']?['totalPoints'] ?? 0,
          'matchesPlayed':
              data['matchesPlayed'] ??
              currentUserData['stats']?['matchesPlayed'] ??
              0,
          'wins': data['wins'] ?? currentUserData['stats']?['wins'] ?? 0,
          'losses': data['losses'] ?? currentUserData['stats']?['losses'] ?? 0,
          'draws': data['draws'] ?? currentUserData['stats']?['draws'] ?? 0,
        };
        currentUserData = {
          ...currentUserData,
          'stats': updatedStats,
          'level': data['tier'] ?? currentUserData['level'],
        };
      });
    });
  }

  @override
  void dispose() {
    SocketService.instance.socket?.off('stats_update');
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username =
        currentUserData['username'] ?? currentUserData['name'] ?? 'Player';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Quiz Arena',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: Logo(size: 70),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () async {
              final updatedGenres = await Navigator.pushNamed(
                context,
                '/profile',
                arguments: {
                  'userId': currentUserData['_id'],
                  'username':
                      currentUserData['username'] ??
                      currentUserData['name'] ??
                      'Player',
                  'tier': currentUserData['level'] ?? 'noob',
                  'points':
                      (currentUserData['stats'] ?? {})['totalPoints'] ?? 0,
                  'matchesPlayed':
                      (currentUserData['stats'] ?? {})['matchesPlayed'] ?? 0,
                  'wins': (currentUserData['stats'] ?? {})['wins'] ?? 0,
                  'draws': (currentUserData['stats'] ?? {})['draws'] ?? 0,
                  'losses': (currentUserData['stats'] ?? {})['losses'] ?? 0,
                  'genres': currentGenres,
                },
              );
              if (updatedGenres != null && updatedGenres is List) {
                setState(() {
                  currentGenres = List<int>.from(updatedGenres);
                  currentUserData = {
                    ...currentUserData,
                    'genres': currentGenres,
                  };
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _entryCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $username!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Ready to challenge someone?',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _modeCard(
                    'Quick Match',
                    'Find Opponent',
                    Icons.flash_on,
                    const Color(0xFF1E88E5),
                    0,
                    () => Navigator.pushNamed(
                      context,
                      '/loadingscreen',
                      arguments: {
                        'userId': currentUserData['_id'],
                        'genres': currentGenres,
                        'userData': currentUserData,
                      },
                    ),
                  ),
                  _modeCard(
                    'Challenge',
                    'Play Friends',
                    Icons.group,
                    Colors.orange,
                    1,
                    () => Navigator.pushNamed(
                      context,
                      '/challenge',
                      arguments: {...currentUserData, 'genres': currentGenres},
                    ),
                  ),
                  _modeCard(
                    'Practice',
                    'Solo Play',
                    Icons.school,
                    Colors.purple,
                    2,
                    () => Navigator.pushNamed(
                      context,
                      '/practice',
                      arguments: {
                        'genres': currentGenres,
                        'userData': currentUserData,
                      },
                    ),
                  ),
                  _modeCard(
                    'Leaderboard',
                    'Top Players',
                    Icons.leaderboard,
                    Colors.green,
                    3,
                    () => Navigator.pushNamed(
                      context,
                      '/leaderboard',
                      arguments: {'userId': currentUserData['_id'] ?? ''},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int index,
    VoidCallback onTap,
  ) {
    final start = index * 0.12;
    final end = (start + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(anim),
        child: _PressCard(
          color: color,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback onTap;
  const _PressCard({
    required this.child,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.94,
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
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
