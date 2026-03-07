import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';
import 'package:quiz_duel/widgets/buttons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_duel/services/constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isHidden = true;
  bool _isLoading = false;

  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(bool isLogin) async {
    setState(() => _isLoading = true);
    final url = isLogin
        ? '${AppConstants.apiUrl}/login'
        : '${AppConstants.apiUrl}/register';
    final body = isLogin
        ? {
            'username': _loginUserCtrl.text.trim(),
            'password': _loginPassCtrl.text,
          }
        : {
            'username': _regUserCtrl.text.trim(),
            'email': _regEmailCtrl.text.trim(),
            'password': _regPassCtrl.text,
          };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

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
      _showError('Connection error. Please check your internet and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );

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
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Logo(size: 100),
                        const SizedBox(height: 12),
                        const Text(
                          'Quiz Royale',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Challenge. Compete. Conquer.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        _buildTabHeader(),
                        const SizedBox(height: 20),
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
        _buildTextField(_loginUserCtrl, 'Username', Icons.person),
        const SizedBox(height: 16),
        _buildTextField(
          _loginPassCtrl,
          'Password',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : AppButton(
                text: 'Login',
                onPressed: () => _handleAuth(true),
                fontSize: 22,
              ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      children: [
        _buildTextField(_regUserCtrl, 'Username', Icons.person),
        const SizedBox(height: 12),
        _buildTextField(_regEmailCtrl, 'Email', Icons.email_outlined),
        const SizedBox(height: 12),
        _buildTextField(_regPassCtrl, 'Password', Icons.lock, isPassword: true),
        const SizedBox(height: 20),
        _isLoading
            ? const CircularProgressIndicator()
            : AppButton(
                text: 'Register',
                onPressed: () => _handleAuth(false),
                fontSize: 22,
              ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword ? _isHidden : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
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
