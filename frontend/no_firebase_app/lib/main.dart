// main.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'providers_setup.dart';
import 'services/navigation_service.dart';
import 'constants.dart';

void loadLocalTrustedCert() async {
  if (!enableTLS) {
    return;
  }
  final ByteData data = await rootBundle.load('assets/certs/rootCA.pem');
  SecurityContext.defaultContext.setTrustedCertificatesBytes(
    data.buffer.asUint8List(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  loadLocalTrustedCert();
  runApp(withProviders(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Notifications & MQTT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
