import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/authentication.dart';
import 'package:quiz_duel/pages/genre.dart';
import 'package:quiz_duel/pages/splash.dart';
import 'package:quiz_duel/pages/homescreen.dart';
import 'package:quiz_duel/pages/profile.dart';
import 'package:quiz_duel/pages/resultscreen.dart';
import 'package:quiz_duel/pages/questionSelection.dart';
import 'package:quiz_duel/pages/loadingscreen.dart';
import 'package:quiz_duel/pages/matchroom.dart';
import 'package:quiz_duel/pages/challengelobby.dart';
import 'package:quiz_duel/pages/challengescreen.dart';
import 'package:quiz_duel/pages/joinroomscreen.dart';
import 'package:quiz_duel/pages/practice.dart';
import 'package:quiz_duel/pages/leaderboard.dart';
import 'package:quiz_duel/services/socket_service.dart';
import 'package:quiz_duel/services/api_service.dart';
import 'package:quiz_duel/services/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init(baseUrl: AppConstants.apiUrl);
  await SocketService.instance.connect(AppConstants.socketUrl);
  runApp(const QuizRoyale());
}

/// Smooth slide-from-right + fade transition used for all routes
Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, anim, secondaryAnim, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut));

      final fade = CurvedAnimation(parent: anim, curve: Curves.easeIn);

      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

class QuizRoyale extends StatelessWidget {
  const QuizRoyale({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Royale',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E88E5),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/genre': (context) => const GenreScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          // ── Loading / Matchmaking ─────────────────────────────
          case '/loadingscreen':
            if (args == null) return _slideRoute(const SplashScreen());
            return _slideRoute(
              LoadingScreen(
                userId: args['userId'] ?? '',
                genres: List<int>.from(args['genres'] ?? []),
                userData: Map<String, dynamic>.from(args['userData'] ?? {}),
              ),
            );

          // ── Question Selection ────────────────────────────────
          case '/questionSelection':
            return _slideRoute(
              QuestionSelectionScreen(
                roomId: args?['roomId'] ?? '',
                userId: args?['userId'] ?? '',
                inventory: args?['inventory'] ?? [],
                timer: args?['timer'] ?? 30,
                socket: SocketService.instance.socket!,
                amIP1: args?['amIP1'] ?? true,
                userData: Map<String, dynamic>.from(args?['userData'] ?? {}),
              ),
            );

          // ── Match Room ────────────────────────────────────────
          case '/matchroom':
            if (args == null ||
                args['roomId'] == null ||
                args['userId'] == null) {
              return _slideRoute(
                const Scaffold(
                  body: Center(child: Text('Error: Missing match data')),
                ),
              );
            }
            return _slideRoute(
              MatchRoomScreen(
                roomId: args['roomId'],
                userId: args['userId'],
                questions: args['questions'] ?? [],
                socket: SocketService.instance.socket!,
                userData: Map<String, dynamic>.from(args['userData'] ?? {}),
              ),
            );

          // ── Result Screen ─────────────────────────────────────
          case '/resultscreen':
            return _slideRoute(
              ResultScreen(
                gameResults: args ?? {},
                socket: SocketService.instance.socket,
                userData: Map<String, dynamic>.from(args?['userData'] ?? {}),
              ),
            );

          // ── Home ──────────────────────────────────────────────
          case '/home':
            return _slideRoute(
              HomeScreen(
                genres: List<int>.from(
                  args?['genres'] ?? args?['preferredGenres'] ?? [],
                ),
                userData: args ?? {},
              ),
            );

          // ── Profile ───────────────────────────────────────────
          case '/profile':
            return _slideRoute(
              ProfileScreen(
                userId: args?['userId'] ?? '',
                username: args?['username'] ?? '',
                tier: args?['tier'] ?? 'noob',
                points: args?['points'] ?? 0,
                matchesPlayed: args?['matchesPlayed'] ?? 0,
                wins: args?['wins'] ?? 0,
                draws: args?['draws'] ?? 0,
                losses: args?['losses'] ?? 0,
                genres: List<int>.from(args?['genres'] ?? []),
                socket: SocketService.instance.socket,
              ),
            );

          // ── Challenge Lobby (Create or Join) ──────────────────
          case '/challenge':
            return _slideRoute(
              ChallengeLobbyScreen(
                userData: Map<String, dynamic>.from(args ?? {}),
              ),
            );

          // ── Create Room ───────────────────────────────────────
          case '/createroom':
            return _slideRoute(
              ChallengeScreen(userData: Map<String, dynamic>.from(args ?? {})),
            );

          // ── Join Room ─────────────────────────────────────────
          case '/joinroom':
            return _slideRoute(
              JoinRoomScreen(userData: Map<String, dynamic>.from(args ?? {})),
            );

          // ── Practice ──────────────────────────────────────────
          case '/practice':
            return _slideRoute(
              PracticeScreen(
                genres: List<int>.from(args?['genres'] ?? []),
                userData: Map<String, dynamic>.from(args?['userData'] ?? {}),
              ),
            );

          // ── Leaderboard ───────────────────────────────────────
          case '/leaderboard':
            return _slideRoute(
              LeaderboardScreen(currentUserId: args?['userId'] ?? ''),
            );

          default:
            return null;
        }
      },
    );
  }
}
