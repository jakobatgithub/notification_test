// widgets/send_notification_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class SendNotificationButton extends StatelessWidget {
  const SendNotificationButton({super.key});

  Future<void> _sendPostRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    if (accessToken == null) {
      debugPrint('❌ No access token found');
      return;
    }

    final response = await http.post(
      Uri.parse("$baseURL/api/notifications/"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({"title": "Notification", "body": "Test body."}),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Post request successful');
    } else {
      debugPrint('❌ Failed to send post request: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _sendPostRequest,
      child: const Text('Send notifications'),
    );
  }
}
