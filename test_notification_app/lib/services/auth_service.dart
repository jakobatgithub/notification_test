import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../constants.dart';

class AuthService {
  static Future<void> login(String username, String password) async {
    String loginURL = "$baseURL/_allauth/browser/v1/auth/login";
    final response = await http.post(
      Uri.parse(loginURL),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      debugPrint('✅ Login successful');
    } else {
      debugPrint('❌ Failed to login: ${response.body}');
    }
  }

  static Future<void> signup(String username, String password) async {
    String signupURL = "$baseURL/_allauth/browser/v1/auth/signup";
    final response = await http.post(
      Uri.parse(signupURL),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Signup successful');
    } else {
      debugPrint('❌ Failed to signup: ${response.body}');
    }
  }

  static Future<void> retrieveTokens(String username, String password) async {
    String tokenURL = "$baseURL/token/access_token/";
    final response = await http.post(
      Uri.parse(tokenURL),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> tokens = jsonDecode(response.body);
      String accessToken = tokens['token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
    } else {
      debugPrint('❌ Failed to retrieve tokens: ${response.body}');
    }
  }

  static Future<void> loginOrSignup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUsername = prefs.getString('username');
    String? storedPassword = prefs.getString('password');

    if (storedUsername != null && storedPassword != null) {
      await retrieveTokens(storedUsername, storedPassword);
    } else {
      String username = _generateRandomString(8);
      String password = _generateRandomString(12);
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await signup(username, password);
      await retrieveTokens(username, password);
    }
  }

  static String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }
}
