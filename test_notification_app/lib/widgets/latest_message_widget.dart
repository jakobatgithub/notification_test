// widgets/latest_message_widget.dart
import 'package:flutter/material.dart';

class LatestMessageWidget extends StatelessWidget {
  final String message;
  const LatestMessageWidget({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Latest MQTT Message:"),
        Text(
          message,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
