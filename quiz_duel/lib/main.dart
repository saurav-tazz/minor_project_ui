import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/authentication.dart';
import 'package:quiz_duel/pages/genre.dart';
import 'pages/splash.dart';
import 'pages/matchroom.dart';
import 'pages/homescreen.dart';
import 'pages/profile.dart';
import 'pages/resultscreen.dart';
import 'pages/questionSelection.dart';

void main() {
  runApp(const QuizDuel());
}

class QuizDuel extends StatelessWidget {
  const QuizDuel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizDuel',
      // home: const QuestionSelectionScreen(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/genre': (context) => const GenreScreen(),

        // '/home': (context) => const HomeScreen(),
        '/questionSelection': (context) => const QuestionSelectionScreen(genres: [],),
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
        // if (settings.name == '/resultscreen') {
        //   final args = settings.arguments as Map<String, dynamic>;
        //   return MaterialPageRoute(
        //     builder: (context) => ResultScreen(
        //       score: args['score'] as int,
        //       totalQuestions: args['totalQuestions'] as int,
        //       genres: List<String>.from(args['genres']),
        //     ),
        //   );
        // }
        if (settings.name == '/resultscreen') {
          return MaterialPageRoute(builder: (context) => const ResultScreen());
        }
        return null;
      },
    );
  }
}
