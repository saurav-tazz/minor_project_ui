import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  final String tier; // "Noob", "Intermediate", "Pro"
  final int points;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final List<String> genres;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.tier,
    required this.points,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.genres,
  });

  @override
  Widget build(BuildContext context) {
    final double winRate =
    matchesPlayed > 0 ? (wins / matchesPlayed * 100) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Username + Tier
            Text(
              username,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  tier,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Points Card
            _buildInfoCard(
              icon: Icons.star,
              label: "Total Points",
              value: points.toString(),
            ),
            const SizedBox(height: 16),

            // Matches Card
            _buildInfoCard(
              icon: Icons.sports_esports,
              label: "Matches",
              value: matchesPlayed.toString(),
            ),
            const SizedBox(height: 16),

            // Win Rate Card
            _buildInfoCard(
              icon: Icons.percent,
              label: "Win Rate",
              value: "${winRate.toStringAsFixed(0)}%",
            ),
            const SizedBox(height: 16),

            // Wins / Draws / Losses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox("Wins", wins, Colors.green),
                _buildStatBox("Draws", draws, Colors.orange),
                _buildStatBox("Losses", losses, Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Genres Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Favorite Genres",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to GenreScreen for editing
                  },
                  child: const Text("Edit"),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: genres
                  .map((g) => Chip(
                label: Text(g),
                backgroundColor: const Color(0xFF42A5F5),
                labelStyle: const TextStyle(color: Colors.white),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E88E5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}