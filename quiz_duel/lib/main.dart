import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/authentication.dart';
import 'package:quiz_duel/pages/genre.dart';
import 'package:quiz_duel/pages/splash.dart';
import 'package:quiz_duel/pages/matchroom.dart';
import 'package:quiz_duel/pages/homescreen.dart';
import 'package:quiz_duel/pages/profile.dart';
import 'package:quiz_duel/pages/resultscreen.dart';
import 'package:quiz_duel/pages/questionSelection.dart';

// Import backend services
import 'package:quiz_duel/services/socket_service.dart';
import 'package:quiz_duel/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. UPDATE THIS IP: This is the address of your Backend Laptop
  const String activeBackendIp = "http://192.168.168.112:4000";

  // 2. Initialize ApiService with the new IP
  ApiService.init(baseUrl: activeBackendIp);

  // 3. Initialize Socket connection
  // Ensure your SocketService.connect() method accepts a URL string!
  await SocketService.instance.connect(activeBackendIp);

  runApp(const QuizDuel());
}

class QuizDuel extends StatelessWidget {
  const QuizDuel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizDuel',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/genre': (context) => const GenreScreen(),
        '/questionSelection': (context) =>
            const QuestionSelectionScreen(genres: []),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/matchroom') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => MatchRoomScreen(genres: args),
          );
        }
        if (settings.name == '/profile') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(
              username: args['username'],
              tier: args['tier'],
              points: args['points'],
              matchesPlayed: args['matchesPlayed'],
              wins: args['wins'],
              draws: args['draws'],
              losses: args['losses'],
              genres: args['genres'],
            ),
          );
        }
        if (settings.name == '/home') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(genres: args),
          );
        }
        if (settings.name == '/resultscreen') {
          return MaterialPageRoute(builder: (context) => const ResultScreen());
        }
        return null;
      },
    );
  }
}
