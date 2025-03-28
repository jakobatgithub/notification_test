// lib/providers_setup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';

Widget withProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DeviceProvider()),
      // Add more providers here as your app grows
    ],
    child: child,
  );
}
