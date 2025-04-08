// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:shared/shared.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MqttService _mqttService;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

    // ✅ Set up lifecycle listener
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint('🔄 App resumed — reconnecting MQTT');
        _mqttService.reconnect();
      },
      onInactive: () {
        debugPrint('📴 App inactive — disconnecting MQTT');
        _mqttService.disconnect();
      },
    );

    AuthService.loginOrSignup().then((_) {
      _initializeServices();
      _loadDevices();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _mqttService.disconnect();
    super.dispose();
  }

  void _initializeServices() {
    _mqttService = MqttService();
    _mqttService.initialize();
  }

  void _loadDevices() async {
    await DevicesService.loadDevicesIntoProvider(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: HomeScreenBody());
  }
}
