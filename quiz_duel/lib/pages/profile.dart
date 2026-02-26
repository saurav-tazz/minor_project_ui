import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String tier; // "Noob", "Intermediate", "Pro"
  final int points;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final List<String> genres;
  final dynamic socket; // Passed from navigation for real-time updates

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
    required this.socket,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Use local variables to allow the UI to react to Socket events
  late int currentPoints;
  late String currentTier;
  late int currentMatchesPlayed;
  late int currentWins;
  late int currentDraws;
  late int currentLosses;

  @override
  void initState() {
    super.initState();
    _initializeStats();

    // 🔹 LISTENER: Handle Real-time Stats Updates from the Server
    widget.socket.on('stats_update', (data) {
      if (mounted) {
        setState(() {
          currentPoints = data['points'] ?? currentPoints;
          currentTier = data['tier'] ?? currentTier;
          currentMatchesPlayed = data['matchesPlayed'] ?? currentMatchesPlayed;
          currentWins = data['wins'] ?? currentWins;
          currentDraws = data['draws'] ?? currentDraws;
          currentLosses = data['losses'] ?? currentLosses;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Stats updated! ⚡"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(15),
          ),
        );
      }
    });
  }

  void _initializeStats() {
    currentPoints = widget.points;
    currentTier = widget.tier;
    currentMatchesPlayed = widget.matchesPlayed;
    currentWins = widget.wins;
    currentDraws = widget.draws;
    currentLosses = widget.losses;
  }

  @override
  void dispose() {
    widget.socket.off('stats_update');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double winRate = currentMatchesPlayed > 0
        ? (currentWins / currentMatchesPlayed * 100)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // 🔹 Stylish Header with Back Button
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1E88E5),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _tierBadge(currentTier),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Win/Loss/Draw Summary Row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox("Wins", currentWins, Colors.green),
                        _buildVerticalDivider(),
                        _buildStatBox("Draws", currentDraws, Colors.orange),
                        _buildVerticalDivider(),
                        _buildStatBox("Losses", currentLosses, Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Core Stats Section
                  const Text(
                    "PERFORMANCE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.star_rounded,
                    label: "Total Points",
                    value: currentPoints.toString(),
                    color: Colors.amber,
                  ),
                  _buildInfoCard(
                    icon: Icons.sports_esports_rounded,
                    label: "Matches Played",
                    value: currentMatchesPlayed.toString(),
                    color: Colors.blueAccent,
                  ),
                  _buildInfoCard(
                    icon: Icons.auto_graph_rounded,
                    label: "Win Rate",
                    value: "${winRate.toStringAsFixed(1)}%",
                    color: Colors.purpleAccent,
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Favorite Genres Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "FAVORITE GENRES",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.genres
                        .map(
                          (g) => Chip(
                            label: Text(g),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            labelStyle: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(String tier) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 4),
          Text(
            tier.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
