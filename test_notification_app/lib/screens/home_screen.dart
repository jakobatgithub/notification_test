// screens/home_screen.dart

import 'package:flutter/material.dart';

import 'home_screen_body.dart';
import '/services/mqtt_service.dart';
import '/services/firebase_service.dart';
import '/services/auth_service.dart';
import '/utils/shared_preferences_util.dart';
import '/services/devices_service.dart';
import '/widgets/device_list_widget.dart';

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
      _loadDevices();
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  void _loadDevices() async {
    await DevicesService.loadDevicesIntoProvider(context);
  }

  void _initializeServices() {
    _mqttService = MQTTService(onMessageReceived: _onMqttMessageReceived);
    _mqttService.initializeMQTT();
    _loadReceivedMQTTMessages();
    _firebaseService = FirebaseService();
    _firebaseService.initializeFirebase();
  }

  void _onMqttMessageReceived(String message) async {
    debugPrint("message = {$message}");
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
      body: Column(children: [Expanded(child: DeviceListWidget())]),
      // body: HomeScreenBody(
      //   mqttMessage: _mqttMessage,
      //   receivedMQTTMessages: _receivedMQTTMessages,
      // ),
    );
  }
}
