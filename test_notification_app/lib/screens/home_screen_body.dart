import 'package:flutter/material.dart';
import '../widgets/latest_message_widget.dart';
import '../widgets/send_notification_button.dart';
import '../widgets/recent_messages_widget.dart';

class HomeScreenBody extends StatelessWidget {
  final String mqttMessage;
  final Set<String> receivedMQTTMessages;

  const HomeScreenBody({
    super.key,
    required this.mqttMessage,
    required this.receivedMQTTMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LatestMessageWidget(message: mqttMessage),
          const SizedBox(height: 20),
          SendNotificationButton(),
          const SizedBox(height: 20),
          const Text("Recent Messages:"),
          RecentMessagesWidget(messages: receivedMQTTMessages),
        ],
      ),
    );
  }
}
