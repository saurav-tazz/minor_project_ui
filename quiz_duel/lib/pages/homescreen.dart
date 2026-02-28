import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/services/socket_service.dart';

class HomeScreen extends StatelessWidget {
  final List<int> genres;
  // userData contains: _id, name, email, level, genres, stats: {wins, losses, etc}
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.genres, required this.userData});

  void _navigateTo(BuildContext context, String route, Object? args) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    // Extracting stats from userData or providing defaults
    final String username = userData['name'] ?? 'Player';
    final String level = userData['level'] ?? 'noob';
    final Map stats = userData['stats'] ?? {};

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
            onPressed: () {
              // Passing actual user data AND the socket instance for real-time updates
              _navigateTo(context, '/profile', {
                'userId': userData['_id'],
                'username': username,
                'tier': level,
                'points': stats['totalPoints'] ?? 0,
                'matchesPlayed': stats['matchesPlayed'] ?? 0,
                'wins': stats['wins'] ?? 0,
                'draws': stats['draws'] ?? 0,
                'losses': stats['losses'] ?? 0,
                'genres': genres,
                'socket': SocketService
                    .instance
                    .socket, // Essential for Profile listeners
              });
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
                    () => _navigateTo(context, '/matchroom', {
                      'userId': userData['_id'],
                      'genres': genres,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Challenge",
                    "Play Friends",
                    Icons.group,
                    Colors.orange,
                    () => _navigateTo(context, '/matchroom', {
                      'userId': userData['_id'],
                      'genres': genres,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Practice",
                    "Solo Play",
                    Icons.school,
                    Colors.purple,
                    () => _navigateTo(context, '/matchroom', {
                      'userId': userData['_id'],
                      'genres': genres,
                    }),
                  ),
                  _buildModeCard(
                    context,
                    "Leaderboard",
                    "Top Players",
                    Icons.leaderboard,
                    Colors.green,
                    () => {}, // To be implemented
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
