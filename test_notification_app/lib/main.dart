import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';
import 'constants.dart';
import 'dart:convert';
import 'dart:io';
import 'auth_service.dart';

Set<String> _receivedMQTTMessages = {}; // Define globally

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// This handles messages when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _mqttMessage = "No MQTT messages yet";
  late MQTTService _mqttService;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    AuthService.login('jakob1', 'learn&fun');
    AuthService.retrieveTokens('jakob1', 'learn&fun').then((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  void _initializeServices() {
    _mqttService = MQTTService(onMessageReceived: _onMqttMessageReceived);
    _mqttService.initializeMQTT();
    _loadReceivedMQTTMessages();
    _firebaseService = FirebaseService();
    _firebaseService.initializeFirebase();
  }

  void _onMqttMessageReceived(String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload
    _receivedMQTTMessages =
        (prefs.getStringList('receivedMQTTMessages') ?? []).toSet();
    _receivedMQTTMessages.add(message);

    await prefs.setStringList(
      'receivedMQTTMessages',
      _receivedMQTTMessages.toList(),
    );

    setState(() {
      _mqttMessage = message;
    });
  }

  Future<void> _loadReceivedMQTTMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload before reading

    List<String>? messages = prefs.getStringList('receivedMQTTMessages');
    if (messages != null) {
      setState(() {
        _receivedMQTTMessages = messages.toSet()..toList().sort();
        if (messages.isNotEmpty) {
          _mqttMessage = messages.last;
        }
      });
    }
  }

  Future<void> _sendPostRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('No access token found');
      return;
    }

    String backendURL = "$BASE_URL/api/send-notifications/";
    final response = await http.post(
      Uri.parse(backendURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{"title": "My Ass!", "body": "My body."}',
    );

    if (response.statusCode == 200) {
      print('Post request successful');
    } else {
      print('Failed to send post request: ${response.body}');
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
        appBar: AppBar(title: const Text("Firebase & MQTT Demo")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Add some space at the top
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Latest MQTT Message:"),
                  Text(
                    _mqttMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendPostRequest,
                    child: const Text('Send notifications'),
                  ),
                  const SizedBox(height: 20),
                  const Text("Recent Messages:"),
                  ..._receivedMQTTMessages
                      .toList()
                      .reversed
                      .take(10)
                      .map(
                        (message) =>
                            Text(message, style: const TextStyle(fontSize: 14)),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Future<void> initializeFirebase() async {
    NotificationSettings settings = await _messaging.requestPermission();
    print("🔐 Permission status: ${settings.authorizationStatus}");

    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("APNs Token: $apnsToken");

    String? token = await _messaging.getToken();
    print("📲 Initial FCM Token: $token");
    if (token != null) {
      registerDevice(token);
    }

    _messaging.onTokenRefresh.listen((token) {
      registerDevice(token);
    });
  }

  Future<void> registerDevice(String token) async {
    final response = await http.post(
      Uri.parse("$BASE_URL/api/devices/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "registration_id": token,
        "type": Platform.isIOS ? "ios" : "android",
      }),
    );

    if (response.statusCode == 201) {
      print("Device registered successfully");
    } else {
      print("Failed to register device: ${response.body}");
    }
  }
}
