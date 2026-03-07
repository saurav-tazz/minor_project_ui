import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/services/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.7, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _ctrl.forward();

    // After animation settles, try auto-login
    Timer(const Duration(milliseconds: 2400), _tryAutoLogin);
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      _goToAuth();
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('${AppConstants.apiUrl}/users/$userId'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        if (user != null && mounted) {
          _fadeNavigate('/home', Map<String, dynamic>.from(user));
          return;
        }
      }
    } catch (_) {
      // Server unreachable — go to auth
    }

    _goToAuth();
  }

  void _goToAuth() {
    if (!mounted) return;
    _fadeNavigate('/auth', null);
  }

  void _fadeNavigate(String route, Object? args) {
    Navigator.pushReplacementNamed(context, route, arguments: args);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Logo(size: 130),
                const SizedBox(height: 24),
                const Text(
                  'Quiz Royale',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Challenge. Compete. Conquer.',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 52),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
