// widgets/recent_messages_widget.dart
import 'package:flutter/material.dart';

class RecentMessagesWidget extends StatelessWidget {
  final Set<String> messages;
  const RecentMessagesWidget({required this.messages, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          messages.isNotEmpty
              ? messages
                  .toList()
                  .reversed
                  .take(10)
                  .map(
                    (message) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList()
              : [
                const Text(
                  "No messages yet",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
    );
  }
}
