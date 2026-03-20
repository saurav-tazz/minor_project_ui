import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quiz_duel/services/constants.dart';
import 'package:quiz_duel/services/socket_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String tier;
  final int points;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final List<int> genres;
  final dynamic socket;

  const ProfileScreen({
    super.key,
    required this.userId,
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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late int currentPoints,
      currentMatchesPlayed,
      currentWins,
      currentDraws,
      currentLosses;
  late String currentTier;
  late List<int> selectedGenres;

  late AnimationController _entryCtrl;

  static const Map<int, String> genreLabels = {
    0: 'Society & Culture',
    1: 'Science & Mathematics',
    2: 'Health',
    3: 'Education & Reference',
    4: 'Computers & Internet',
    5: 'Sports',
    6: 'Business & Finance',
    7: 'Entertainment & Music',
    8: 'Family & Relationships',
    9: 'Politics & Government',
  };

  @override
  void initState() {
    super.initState();
    _initStats();
    selectedGenres = List.from(widget.genres);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fetchLatestStats();

    widget.socket?.on('stats_update', (data) {
      if (!mounted) return;
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
          content: Text('Stats updated! ⚡'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(15),
        ),
      );
    });
  }

  void _initStats() {
    currentPoints = widget.points;
    currentTier = widget.tier;
    currentMatchesPlayed = widget.matchesPlayed;
    currentWins = widget.wins;
    currentDraws = widget.draws;
    currentLosses = widget.losses;
  }

  Future<void> _fetchLatestStats() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiUrl}/users/${widget.userId}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'];
        final stats = user['stats'] ?? {};
        if (mounted) {
          setState(() {
            currentPoints = stats['totalPoints'] ?? currentPoints;
            currentTier = user['level'] ?? currentTier;
            currentMatchesPlayed =
                stats['matchesPlayed'] ?? currentMatchesPlayed;
            currentWins = stats['wins'] ?? currentWins;
            currentDraws = stats['draws'] ?? currentDraws;
            currentLosses = stats['losses'] ?? currentLosses;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.socket?.off('stats_update');
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winRate = currentMatchesPlayed > 0
        ? (currentWins / currentMatchesPlayed * 100)
        : 0.0;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, selectedGenres);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1E88E5),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context, selectedGenres),
              ),
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
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
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
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Win / Draw / Loss row
                    FadeTransition(
                      opacity: _entryCtrl,
                      child: Container(
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
                            _statBox('Wins', currentWins, Colors.green),
                            _vDivider(),
                            _statBox('Draws', currentDraws, Colors.orange),
                            _vDivider(),
                            _statBox('Losses', currentLosses, Colors.red),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'PERFORMANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _infoCard(
                      icon: Icons.star_rounded,
                      label: 'Total Points',
                      value: currentPoints.toString(),
                      color: Colors.amber,
                    ),
                    _infoCard(
                      icon: Icons.sports_esports_rounded,
                      label: 'Matches Played',
                      value: currentMatchesPlayed.toString(),
                      color: Colors.blueAccent,
                    ),
                    _infoCard(
                      icon: Icons.auto_graph_rounded,
                      label: 'Win Rate',
                      value: '${winRate.toStringAsFixed(1)}%',
                      color: Colors.purpleAccent,
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FAVORITE GENRES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextButton(
                          onPressed: _editGenres,
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: selectedGenres
                          .asMap()
                          .entries
                          .where((e) => e.value == 1)
                          .map((e) {
                            final label = genreLabels[e.key] ?? 'Unknown';
                            return Chip(
                              label: Text(label),
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
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            SocketService.instance.socket?.disconnect();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/auth',
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Genre edit dialog ──────────────────────────────────────
  void _editGenres() async {
    final Set<int> selected = selectedGenres
        .asMap()
        .entries
        .where((e) => e.value == 1)
        .map((e) => e.key)
        .toSet();

    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Favorite Genres'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (ctx, setS) => ListView(
              shrinkWrap: true,
              children: genreLabels.keys
                  .map(
                    (g) => CheckboxListTile(
                      title: Text(genreLabels[g]!),
                      value: selected.contains(g),
                      onChanged: (val) => setS(
                        () => val! ? selected.add(g) : selected.remove(g),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final binary = List.filled(10, 0);
      for (var g in result) {
        binary[g] = 1;
      }
      setState(() => selectedGenres = binary);
      await _syncGenres(binary);
    }
  }

  Future<void> _syncGenres(List<int> genres) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiUrl}/users/update-genres'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId, 'preferredGenres': genres}),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Genres updated ✅'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  // ── Helper widgets ─────────────────────────────────────────
  Widget _tierBadge(String tier) => Container(
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

  Widget _vDivider() =>
      Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));

  Widget _statBox(String label, int value, Color color) => Column(
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

  Widget _infoCard({
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
}
