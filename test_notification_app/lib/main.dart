import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'mqtt_service.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// This handles messages when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Received a Firebase message onBackgroundMessage");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _mqttMessage = "No MQTT messages yet";
  String _firebaseMessage = "No Firebase messages yet";
  late MQTTService _mqttService;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _mqttService = MQTTService(onMessageReceived: _onMqttMessageReceived);
    _mqttService.initializeMQTT();

    _firebaseService = FirebaseService(onMessageReceived: _onFirebaseMessageReceived);
    _firebaseService.initializeFirebase();
  }

  void _onMqttMessageReceived(String message) {
    setState(() {
      _mqttMessage = message;
    });
  }

  void _onFirebaseMessageReceived(String message) {
    setState(() {
      _firebaseMessage = message;
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  Future<void> _sendPostRequest() async {
    String backendURL = "$BASE_URL/send-notifications/";
    final response = await http.post(
      Uri.parse(backendURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: '{"title": "My Ass!", "body": "My body."}',
    );

    if (response.statusCode == 200) {
      print('Post request successful');
    } else {
      print('Failed to send post request');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notifications & MQTT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Firebase & MQTT Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Latest Firebase Message:"),
              Text(
                _firebaseMessage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text("Latest MQTT Message:"),
              Text(
                _mqttMessage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendPostRequest,
                child: const Text('Send notifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    _messaging.onTokenRefresh.listen(sendTokenToBackend);

    FirebaseMessaging.onMessage.listen(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
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

  void handleMessage(RemoteMessage message) {
    if (message.data.isNotEmpty && message.notification == null) {
      print("Received a Firebase message with data.");
      String messageId = message.data['msg_id'] ?? "No message ID";
      String title = message.data['title'] ?? "No message title";
      String body = message.data['body'] ?? "No message body";
      print("msg_id: $messageId, title: $title, body: $body");
      onMessageReceived("msg_id: $messageId, title: $title, body: $body");
    } else {
      print("Received a Firebase notification message without data.");
    }
  }
}
