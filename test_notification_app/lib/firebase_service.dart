import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initializeFirebase() async {
    NotificationSettings settings = await _messaging.requestPermission();
    print("🔐 Permission status: ${settings.authorizationStatus}");

    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("APNs Token: $apnsToken");

    String? token = await _messaging.getToken();
    print("📲 Initial FCM Token: $token");
    if (token != null) sendTokenToBackend(token);

    _messaging.onTokenRefresh.listen((newToken) {
      print("🔄 Token Refreshed: $newToken");
      sendTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Received Firebase Message: ${message.notification?.title}");
    });
  }

  static void sendTokenToBackend(String token) async {
    var backendURL = "http://192.168.178.33:8000/register-token/";
    var response = await http.post(
      Uri.parse(backendURL),
      headers: {"Content-Type": "application/json"},
      body: '{"token": "$token"}',
    );
    print("✅ Token Sent to Backend: ${response.body}");
  }
}
