// widgets/latest_message_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/message_provider.dart';

class LatestMessageWidget extends StatelessWidget {
  const LatestMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, provider, _) {
        final latest =
            provider.messages.isNotEmpty ? provider.messages.last : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Latest MQTT Message:"),
            Text(
              latest != null
                  ? '${latest.title}: ${latest.body}'
                  : 'No messages yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
