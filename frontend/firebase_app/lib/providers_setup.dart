// lib/providers_setup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/device_provider.dart';
import 'providers/message_provider.dart';

Widget withProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ChangeNotifierProvider(create: (_) => MessageProvider()),
    ],
    child: child,
  );
}
