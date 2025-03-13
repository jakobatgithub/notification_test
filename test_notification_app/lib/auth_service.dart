import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'constants.dart';

class AuthService {
  static Future<void> login(String username, String password) async {
    String loginURL = "$BASE_URL/_allauth/browser/v1/auth/login";
    final response = await http.post(
      Uri.parse(loginURL),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      print('Login successful');
    } else {
      print('Failed to login: ${response.body}');
    }
  }

  static Future<void> retrieveTokens(String username, String password) async {
    String tokenURL = "$BASE_URL/api/token/";
    final response = await http.post(
      Uri.parse(tokenURL),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> tokens = jsonDecode(response.body);
      String accessToken = tokens['access'];
      String refreshToken = tokens['refresh'];
      print('Access Token: $accessToken');
      print('Refresh Token: $refreshToken');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
    } else {
      print('Failed to retrieve tokens: ${response.body}');
    }
  }
}
