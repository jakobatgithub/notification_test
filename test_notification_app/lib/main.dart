import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
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

    _mqttService = MQTTService(onMessageReceived: (message) {
      setState(() {
        _mqttMessage = message;
      });
    });
    _mqttService.initializeMQTT(); // Initialize MQTT

    _firebaseService = FirebaseService(onMessageReceived: (message) {
      setState(() {
        _firebaseMessage = message;
      });
    });
    _firebaseService.initializeFirebase(); // Initialize Firebase
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