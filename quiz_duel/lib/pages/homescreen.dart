import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  final List<int> genres;
  // userData contains: _id, name, email, level, genres, stats: {wins, losses, etc}
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.genres, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<int> currentGenres; // ADD
  late Map<String, dynamic> currentUserData; // ADD
  @override
  void initState() {
    super.initState();
    currentGenres = widget.genres;
    currentUserData = widget.userData;
    _listenForStatsUpdate(); // Listen for real-time stats updates
  }

  void _listenForStatsUpdate() {
    SocketService.instance.socket?.on('stats_update', (data) {
      if (mounted) {
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
            'losses':
                data['losses'] ?? currentUserData['stats']?['losses'] ?? 0,
            'draws': data['draws'] ?? currentUserData['stats']?['draws'] ?? 0,
          };
          currentUserData = {
            ...currentUserData,
            'stats': updatedStats,
            'level': data['tier'] ?? currentUserData['level'],
          };
        });
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.socket?.off('stats_update');
    super.dispose();
  }

  void _navigateTo(BuildContext context, String route, Object? args) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    // Extracting stats from userData or providing defaults
    final String username =
        currentUserData['username'] ?? currentUserData['name'] ?? 'Player';
    // final String level = currentUserData['level'] ?? 'noob';
    // final Map stats = currentUserData['stats'] ?? {};
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Quiz Arena",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back, $username!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Ready to challenge someone?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildModeCard(
                    context,
                    "Quick Match",
                    "Find Opponent",
                    Icons.flash_on,
                    const Color(0xFF1E88E5),
                    () => _navigateTo(context, '/loadingscreen', {
                      'userId': currentUserData['_id'],
                      'genres': currentGenres,
                      'userData': currentUserData,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Challenge",
                    "Play Friends",
                    Icons.group,
                    Colors.orange,
                    () => _navigateTo(context, '/challenge', {
                      'userId': widget.userData['_id'],
                      'genres': widget.genres,
                      'userData': widget.userData,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Practice",
                    "Solo Play",
                    Icons.school,
                    Colors.purple,
                    () => _navigateTo(context, '/practice', {
                      'genres': currentGenres,
                      'userData': currentUserData,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Leaderboard",
                    "Top Players",
                    Icons.leaderboard,
                    Colors.green,
                    () => Navigator.pushNamed(
                      context,
                      '/leaderboard',
                      arguments: {'userId': currentUserData['_id'] ?? ''},
                    ), // To be implemented
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
    );
  }
}
