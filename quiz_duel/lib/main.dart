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

import 'package:quiz_duel/services/socket_service.dart';
import 'package:quiz_duel/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REST API BASE
  const String apiBase = "https://quiz-royale-ash0.onrender.com/api";

  // ✅ SOCKET BASE (NO /api)
  const String socketBase = "https://quiz-royale-ash0.onrender.com";

  ApiService.init(baseUrl: apiBase);

  await SocketService.instance.connect(socketBase);

  runApp(const QuizRoyale());
}

class QuizRoyale extends StatelessWidget {
  const QuizRoyale({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuiRoyale',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/genre': (context) => const GenreScreen(),

        '/loadingscreen': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;

          return LoadingScreen(
            userId: args['userId'],
            genres: List<int>.from(args['genres']),
            // socket: SocketService.instance.socket!,
          );
        },
      },

      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        // ✅ QUESTION SELECTION
        if (settings.name == '/questionSelection') {
          return MaterialPageRoute(
            builder: (_) => QuestionSelectionScreen(
              roomId: args?['roomId'],
              userId: args?['userId'],
              inventory: args?['inventory'],
              timer: args?['timer'],
              socket: SocketService.instance.socket!,
              amIP1: args?['amIP1'] ?? true, // default to true if not provided
            ),
          );
        }

        //MATCHROOM (DUEL SCREEN)
        // if (settings.name == '/matchroom') {
        //   return MaterialPageRoute(
        //     builder: (_) => MatchRoomScreen(
        //       roomId: args?['roomId'],
        //       userId: args?['userId'],
        //       questions: args?['questions'] ?? [],
        //       socket: SocketService.instance.socket!,
        //     ),
        //   );
        // }
        //MATCHROOM (DUEL SCREEN) with argument validation
        if (settings.name == '/matchroom') {
          final args = settings.arguments as Map<String, dynamic>?;

          // Validate that we actually have the required data
          if (args == null ||
              args['roomId'] == null ||
              args['userId'] == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Error: Missing Match Data")),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) => MatchRoomScreen(
              roomId: args['roomId'], // No more '?' needed here after the check
              userId: args['userId'],
              questions: args['questions'] ?? [],
              socket: SocketService.instance.socket!,
            ),
          );
        }

        // ✅ PROFILE
        if (settings.name == '/profile') {
          return MaterialPageRoute(
            builder: (_) => ProfileScreen(
              userId: args?['userId'],
              username: args?['username'],
              tier: args?['tier'],
              points: args?['points'],
              matchesPlayed: args?['matchesPlayed'],
              wins: args?['wins'],
              draws: args?['draws'],
              losses: args?['losses'],
              genres: args?['genres'],
              socket: SocketService.instance.socket,
            ),
          );
        }

        // ✅ HOME
        if (settings.name == '/home') {
          return MaterialPageRoute(
            builder: (_) => HomeScreen(
              genres: List<int>.from(args?['genres'] ?? []),
              userData: args ?? {},
            ),
          );
        }

        // ✅ RESULT SCREEN
        if (settings.name == '/resultscreen') {
          return MaterialPageRoute(
            builder: (_) => ResultScreen(
              gameResults: args ?? {},
              socket: SocketService.instance.socket,
            ),
          );
        }

        return null;
      },
    );
  }
}
