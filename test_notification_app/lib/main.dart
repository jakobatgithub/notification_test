import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';
import 'constants.dart';

Set<String> _receivedMessages = {}; // Define globally

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
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Force reload before reading

  print("Received a Firebase message onBackgroundMessage");

  if (message.data.isNotEmpty && message.notification == null) {
    print("Received a Firebase message with data.");
    String messageId = message.data['msg_id'] ?? "No message ID";
    String title = message.data['title'] ?? "No message title";
    String body = message.data['body'] ?? "No message body";
    String fullMessage = "msg_id: $messageId, title: $title, body: $body";
    print("messageId of latest message is $messageId");

    _receivedMessages = (prefs.getStringList('receivedMessages') ?? []).toSet();
    _receivedMessages.add(fullMessage);
    bool success1 = await prefs.setString('latestMessage', fullMessage);
    bool success2 = await prefs.setStringList('receivedMessages', _receivedMessages.toList());
    print("✅ SharedPreferences updated: $success1 and $success2");
    print("Latest message updated: $fullMessage");

  } else {
    print("Received a Firebase notification message without data.");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _mqttMessage = "No MQTT messages yet";
  String _firebaseMessage = "No Firebase messages yet";
  late MQTTService _mqttService;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    WidgetsBinding.instance.addObserver(this);
    _loadLatestMessage();
    _loadReceivedMessages();
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("App state changed: $state");
    if (state == AppLifecycleState.resumed) {
      print("App state resumed, loading latest message...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();  // Force reload

      String? latestMessage = prefs.getString('latestMessage');
      print("Load latest message: $latestMessage");
      if (latestMessage != null) {
        setState(() {
          _firebaseMessage = latestMessage;
        });
      } else {
        print("No latest message found");
      }

      List<String>? messages = prefs.getStringList('receivedMessages');
      if (messages != null) {
        setState(() {
          _receivedMessages = messages.toSet()..toList().sort();
        });
      }
    }
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

  Future<void> _loadLatestMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload before reading

    String? latestMessage = prefs.getString('latestMessage');
    print("Load latest message: $latestMessage");
    if (latestMessage != null) {
      setState(() {
        _firebaseMessage = latestMessage;
      });
    }
  }

  Future<void> _loadReceivedMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload before reading
    
    List<String>? messages = prefs.getStringList('receivedMessages');
    if (messages != null) {
      setState(() {
        _receivedMessages = messages.toSet()..toList().sort();
      });
    }
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
              const SizedBox(height: 20),
              const Text("Recent Messages:"),
              ..._receivedMessages.toList().reversed.take(10).map((message) => Text(
                message,
                style: const TextStyle(fontSize: 14),
              )).toList(),
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

  void handleMessage(RemoteMessage message) async {
    if (message.data.isNotEmpty && message.notification == null) {
      print("Received a Firebase message with data.");
      
      String messageId = message.data['msg_id'] ?? "0";
      String title = message.data['title'] ?? "No message title";
      String body = message.data['body'] ?? "No message body";
      String fullMessage = "msg_id: $messageId, title: $title, body: $body";
      
      onMessageReceived(fullMessage);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload before reading
      
      _receivedMessages = (prefs.getStringList('receivedMessages') ?? []).toSet();
      _receivedMessages.add(fullMessage);
      
      bool success1 = await prefs.setString('latestMessage', fullMessage);
      bool success2 = await prefs.setStringList('receivedMessages', _receivedMessages.toList());
      
      print("✅ SharedPreferences updated: $success1 and $success2");
      print("Latest message updated: $fullMessage");

    } else {
      print("Received a Firebase notification message without data.");
    }
  }
}
