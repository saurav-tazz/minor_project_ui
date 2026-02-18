import 'package:flutter/material.dart';
import 'package:quiz_duel/pages/authentication.dart';
import 'package:quiz_duel/pages/genre.dart';
import 'pages/splash.dart';
import 'pages/matchroom.dart';
import 'pages/homescreen.dart';
import 'pages/profile.dart';
import 'pages/rough.dart';

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
        // '/rough': (context) => const ResultScreen(),

      },
      onGenerateRoute: (settings) {
        if (settings.name == '/matchroom') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => MatchRoomScreen(genres: args),
          );
        }
        if (settings.name == '/profile') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(genres: args),
          );
        }
        if (settings.name == '/home') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(genres: args),
          );
        }
        if (settings.name == '/rough') {
          final args = settings.arguments as List<String>; // list of 10 questions
          return MaterialPageRoute(
            builder: (context) => QuestionSelectionScreen(questions: args),
          );
        }
        return null;
      },

    );
  }
}
