// services/firebase_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeFirebase() async {
    NotificationSettings settings = await _messaging.requestPermission();
    debugPrint("🔐 Permission status: ${settings.authorizationStatus}");

    String? token = await _messaging.getToken();
    if (token != null) {
      registerDevice(token);
    }
    _messaging.onTokenRefresh.listen(registerDevice);
  }

  Future<void> registerDevice(String token) async {
    final response = await http.post(
      Uri.parse("$baseURL/api/fcm/devices/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "registration_id": token,
        "type": Platform.isIOS ? "ios" : "android",
      }),
    );

    debugPrint(
      response.statusCode == 201 || response.statusCode == 200
          ? "✅ Device registered successfully"
          : "❌ Failed to register device: ${response.body}",
    );
  }
}
