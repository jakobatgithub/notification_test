import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_service.dart'; // Import Firebase service
// import 'mqtt_service.dart'; // Import MQTT service
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http; // Import http package

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'dart:convert';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _mqttMessage = "No MQTT messages yet";
  String _firebaseMessage = "No Firebase messages yet";
  late MqttServerClient client;
  // late MQTTService _mqttService;

  @override
  void initState() {
    super.initState();
    FirebaseService.initializeFirebase(); // Initialize Firebase
    // _mqttService = MQTTService(onMessageReceived: (message) {
    //   print(message);
    //   setState(() {
    //     _mqttMessage = message;
    //   });
    // });
    // _mqttService.initializeMQTT(); // Initialize MQTT
    connectToMqtt();
    _setupFirebaseMessagingListeners(); // Setup Firebase listeners
  }

  Future<void> connectToMqtt() async {
    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient('mqtt.eclipseprojects.io', clientId);
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);
    client.onConnected = () => debugPrint('Connected to MQTT broker');
    client.onDisconnected = () => debugPrint('Disconnected from MQTT broker');
    client.autoReconnect = true;  // Automatically reconnect on disconnection

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('Connection failed: $e');
      return;
    }

    client.subscribe("test/PROSUMIO_NOTIFICATIONS", MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMessage = c![0].payload as MqttPublishMessage;

      final payloadBytes = recMessage.payload.message;

      debugPrint('Received MQTT message: $payloadBytes');

      try {
        final payload = utf8.decode(payloadBytes);
        debugPrint('Decoded MQTT message: $payload');

        setState(() {
          _mqttMessage = payload;
        });
      } catch (e) {
        debugPrint('Error decoding payload: $e');
      }
    });
    }

  @override
  void dispose() {
    // _mqttService.disconnect();
    client.disconnect();
    super.dispose();
  }

  Future<void> _sendPostRequest() async {
    final response = await http.post(
      Uri.parse("http://192.168.178.33:8000/send-notifications/"),
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

  void _setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _firebaseMessage = message.notification?.body ?? "No message body";
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _firebaseMessage = message.notification?.body ?? "No message body";
      });
    });
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