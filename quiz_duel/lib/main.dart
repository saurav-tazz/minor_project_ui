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
import 'package:quiz_duel/pages/practice.dart';
import 'package:quiz_duel/pages/leaderboard.dart';
import 'package:quiz_duel/services/socket_service.dart';
import 'package:quiz_duel/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.init(baseUrl: "https://quiz-royale-ash0.onrender.com/api");
  await SocketService.instance.connect("https://quiz-royale-ash0.onrender.com");

  runApp(const QuizRoyale());
}

class QuizRoyale extends StatelessWidget {
  const QuizRoyale({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Royale',
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case '/':
        return _route(const SplashScreen());

      case '/auth':
        return _route(const AuthScreen());

      case '/genre':
        return _route(const GenreScreen());

      case '/home':
        return _route(
          HomeScreen(
            genres: List<int>.from(args?['genres'] ?? []),
            userData: args ?? {},
          ),
        );

      case '/loadingscreen':
        if (args == null) return _route(const SplashScreen());
        return _route(
          LoadingScreen(
            userId: args['userId'] ?? '',
            genres: List<int>.from(args['genres'] ?? []),
            userData: Map<String, dynamic>.from(args['userData'] ?? {}),
          ),
        );

      case '/questionSelection':
        return _route(
          QuestionSelectionScreen(
            roomId: args?['roomId'],
            userId: args?['userId'],
            inventory: args?['inventory'],
            timer: args?['timer'],
            socket: SocketService.instance.socket!,
            amIP1: args?['amIP1'] ?? true,
            userData: Map<String, dynamic>.from(args?['userData'] ?? {}),
          ),
        );

      case '/matchroom':
        if (args == null || args['roomId'] == null || args['userId'] == null) {
          return _route(
            const Scaffold(
              body: Center(child: Text("Error: Missing Match Data")),
            ),
          );
        }
        return _route(
          MatchRoomScreen(
            roomId: args['roomId'],
            userId: args['userId'],
            questions: args['questions'] ?? [],
            socket: SocketService.instance.socket!,
            userData: Map<String, dynamic>.from(args['userData'] ?? {}),
          ),
        );

      case '/profile':
        return _route(
          ProfileScreen(
            userId: args?['userId'] ?? '',
            username: args?['username'] ?? '',
            tier: args?['tier'] ?? '',
            points: args?['points'] ?? 0,
            matchesPlayed: args?['matchesPlayed'] ?? 0,
            wins: args?['wins'] ?? 0,
            draws: args?['draws'] ?? 0,
            losses: args?['losses'] ?? 0,
            genres: List<int>.from(args?['genres'] ?? []),
            socket: SocketService.instance.socket,
          ),
        );

      case '/resultscreen':
        return _route(
          ResultScreen(
            gameResults: args ?? {},
            socket: SocketService.instance.socket,
            userData: args?['userData'] ?? {},
          ),
        );

      case '/challenge':
        return _route(
          ChallengeLobbyScreen(userData: Map<String, dynamic>.from(args ?? {})),
        );

      case '/practice':
        return _route(
          PracticeScreen(
            genres: List<int>.from(args?['genres'] ?? []),
            userData: Map<String, dynamic>.from(args?['userData'] ?? {}),
          ),
        );

      case '/leaderboard':
        return _route(LeaderboardScreen(currentUserId: args?['userId'] ?? ''));

      default:
        return null;
    }
  }

  MaterialPageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
