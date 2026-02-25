import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _baseUrl;

  static void init({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  // Handle User Registration
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return {
        'success': response.statusCode == 201,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Handle User Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
