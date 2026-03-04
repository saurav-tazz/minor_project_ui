// leaderboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiz_duel/services/socket_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String currentUserId;

  const LeaderboardScreen({super.key, required this.currentUserId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _hasError = false;

  // ── ADJUST THIS NUMBER to control how many players appear ──
  static const int _leaderboardLimit = 50;

  static const Map<String, Map<String, dynamic>> _tierConfig = {
    'noob': {'label': 'noob', 'color': Color(0xFF78909C), 'icon': Icons.bolt},
    'intermediate': {
      'label': 'intermediate',
      'color': Color(0xFF1E88E5),
      'icon': Icons.bolt,
    },
    'pro': {
      'label': 'pro',
      'color': Color(0xFFFFB300),
      'icon': Icons.workspace_premium,
    },
  };

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _requestLeaderboard();
  }

  void _setupSocketListeners() {
    SocketService.instance.socket?.on('leaderboard_update', (data) {
      if (!mounted) return;
      final raw = data['leaderboard'] as List<dynamic>? ?? [];
      setState(() {
        _leaderboard = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
        _hasError = false;
      });
    });

    SocketService.instance.socket?.on('error', (data) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  void _requestLeaderboard() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    SocketService.instance.socket?.emit('get_leaderboard', {
      'limit': _leaderboardLimit,
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.socket?.off('leaderboard_update');
    SocketService.instance.socket?.off('error');
    super.dispose();
  }

  // ── Rank widget — medal emoji for top 3, plain number for rest ──

  Widget _rankWidget(int rank) {
    if (rank == 1) return const Text('🥇', style: TextStyle(fontSize: 26));
    if (rank == 2) return const Text('🥈', style: TextStyle(fontSize: 26));
    if (rank == 3) return const Text('🥉', style: TextStyle(fontSize: 26));
    return Text(
      '$rank',
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Colors.black54,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myEntry = _leaderboard.firstWhere(
      (p) => p['userId'].toString() == widget.currentUserId,
      orElse: () => {},
    );
    final myRank = myEntry.isNotEmpty ? myEntry['rank'] as int? : null;
    final myPoints = myEntry.isNotEmpty ? myEntry['points'] ?? 0 : 0;

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
              _buildAppBar(),

              // "Your Rank" banner — only shown if user is in the list
              if (!_isLoading && !_hasError && myRank != null)
                _buildMyRankBanner(myRank, myPoints),

              const SizedBox(height: 16),

              // White rounded container holding the list
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: _isLoading
                        ? const _LoadingState()
                        : _hasError
                        ? _ErrorState(onRetry: _requestLeaderboard)
                        : _leaderboard.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            itemCount: _leaderboard.length,
                            itemBuilder: (context, index) =>
                                _buildPlayerCard(_leaderboard[index]),
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

  // ── App Bar ────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
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
          const Icon(Icons.emoji_events, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: _requestLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ── My Rank Banner ─────────────────────────────────────────

  Widget _buildMyRankBanner(int rank, dynamic points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Rank',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Player Card ────────────────────────────────────────────

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final isMe = player['userId'].toString() == widget.currentUserId;
    final rank = player['rank'] as int? ?? 0;
    final tierKey = (player['tier'] ?? 'noob').toString().toLowerCase();
    final tierConf = _tierConfig[tierKey] ?? _tierConfig['noob']!;
    final winRate = player['winRate']?.toString() ?? '0.0';
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Gold tint for top 3, light blue for current user, white otherwise
        color: isMe
            ? const Color(0xFFE3F2FD)
            : isTopThree
            ? const Color(0xFFFFFDE7)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? const Color(0xFF1E88E5)
              : isTopThree
              ? Colors.amber.withOpacity(0.5)
              : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank
            SizedBox(width: 36, child: Center(child: _rankWidget(rank))),

            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: (tierConf['color'] as Color).withOpacity(0.15),
              child: Text(
                (player['name'] ?? '?')[0].toUpperCase(),
                style: TextStyle(
                  color: tierConf['color'] as Color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name + tier + win rate
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isMe
                                ? const Color(0xFF1E88E5)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (tierConf['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tierConf['icon'] as IconData,
                              size: 11,
                              color: tierConf['color'] as Color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tierConf['label'] as String,
                              style: TextStyle(
                                color: tierConf['color'] as Color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$winRate% WR',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player['points']}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'points',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting state widgets ───────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5)),
          SizedBox(height: 20),
          Text(
            'Fetching rankings...',
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.black26, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Could not load leaderboard',
            style: TextStyle(color: Colors.black45, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🏆', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text(
            'No players yet.\nBe the first to play!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
