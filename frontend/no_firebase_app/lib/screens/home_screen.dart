// screens/home_screen.dart

import 'package:flutter/material.dart';

import 'package:shared/shared.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MqttService _mqttService;

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
    _mqttService = MqttService();
    _mqttService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Firebase & MQTT Demo")),
      // body: Column(children: [Expanded(child: DeviceListWidget())]),
      body: HomeScreenBody(),
    );
  }
}
