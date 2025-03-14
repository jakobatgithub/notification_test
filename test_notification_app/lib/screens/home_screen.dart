// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/latest_message_widget.dart';
import '../widgets/send_notification_button.dart';
import '../widgets/recent_messages_widget.dart';
import '../utils/shared_preferences_util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mqttMessage = "No MQTT messages yet";
  late MQTTService _mqttService;
  late FirebaseService _firebaseService;
  Set<String> _receivedMQTTMessages = {};

  @override
  void initState() {
    super.initState();
    AuthService.loginOrSignup().then((_) {
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
    await SharedPreferencesUtil.addMQTTMessage(message);
    Set<String> receivedMQTTMessagesTemp =
        await SharedPreferencesUtil.loadMQTTMessages();
    setState(() {
      _mqttMessage = message;
      _receivedMQTTMessages = receivedMQTTMessagesTemp;
    });
  }

  Future<void> _loadReceivedMQTTMessages() async {
    Set<String> receivedMQTTMessagesTemp =
        await SharedPreferencesUtil.loadMQTTMessages();
    if (receivedMQTTMessagesTemp.isNotEmpty) {
      setState(() {
        _mqttMessage = receivedMQTTMessagesTemp.last;
        _receivedMQTTMessages = receivedMQTTMessagesTemp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase & MQTT Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LatestMessageWidget(message: _mqttMessage),
            const SizedBox(height: 20),
            SendNotificationButton(),
            const SizedBox(height: 20),
            const Text("Recent Messages:"),
            RecentMessagesWidget(messages: _receivedMQTTMessages),
          ],
        ),
      ),
    );
  }
}
