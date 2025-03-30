// widgets/recent_messages_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/message_provider.dart';
import '/models/message.dart';

class RecentMessagesWidget extends StatelessWidget {
  const RecentMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, provider, _) {
        final List<Message> messages = provider.messages.reversed.toList();

        if (messages.isEmpty) {
          return const Text(
            "No messages yet",
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              messages.take(10).map((message) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${message.title}: ${message.body}',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
