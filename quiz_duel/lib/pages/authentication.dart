import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/widgets/buttons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isHidden = true;
  bool _isLoading = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  // 🔹 Use your active backend IP (Synced with main.dart)
  static const String baseUrl = "http://192.168.168.112:4000";
  Future<void> _handleAuth(bool isLogin) async {
    setState(() => _isLoading = true);

    final url = isLogin ? '$baseUrl/api/login' : '$baseUrl/api/register';

    final body = isLogin
        ? {
            'username': _loginEmailController.text
                .trim(), // backend expects username
            'password': _loginPasswordController.text,
          }
        : {
            'username': _regUsernameController.text.trim(),
            'email': _regEmailController.text.trim(),
            'password': _regPasswordController.text,
          };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      // if (data['success'] == true && data['user'] != null)
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['user']['_id']);

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          isLogin ? '/home' : '/genre',
          arguments: data['user'],
        );
      } else {
        _showError(data['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      _showError('Connection error. Is the server running?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Logo(size: 100),
                    const SizedBox(height: 16),
                    const Text(
                      'Quiz Duel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTabHeader(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        children: [_buildLogin(), _buildRegister()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      child: TabBar(
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black45,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Register'),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _buildTextField(_loginEmailController, 'Email', Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(
          _loginPasswordController,
          'Password',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : AppButton(
                text: "Login",
                onPressed: () => _handleAuth(true),
                fontSize: 22,
              ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      children: [
        _buildTextField(_regUsernameController, 'Username', Icons.person),
        const SizedBox(height: 16),
        _buildTextField(_regEmailController, 'Email', Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(
          _regPasswordController,
          'Password',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : AppButton(
                text: "Register",
                onPressed: () => _handleAuth(false),
                fontSize: 22,
              ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isHidden : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.black45),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isHidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isHidden = !_isHidden),
              )
            : null,
      ),
    );
  }
}
