import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Function(String) onMessageReceived;

  FirebaseService({required this.onMessageReceived});

  Future<void> initializeFirebase() async {

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

    setupFirebaseMessagingListeners();
  }

  static void sendTokenToBackend(String token) async {
    var backendURL = "$BASE_URL/register-token/";
    var response = await http.post(
      Uri.parse(backendURL),
      headers: {"Content-Type": "application/json"},
      body: '{"token": "$token"}',
    );
    print("✅ Token Sent to Backend: ${response.body}");
  }

  void setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String messageId = (message.data['message_id'] ?? 0).toString();
      String title = message.notification?.title ?? "No message title";
      String body = message.notification?.body ?? "No message body";
      onMessageReceived("message_id: $messageId, title: $title, body: $body");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String messageId = (message.data['message_id'] ?? 0).toString();
      String title = message.notification?.title ?? "No message title";
      String body = message.notification?.body ?? "No message body";
      onMessageReceived("message_id: $messageId, title: $title, body: $body");
    });
  }
}
