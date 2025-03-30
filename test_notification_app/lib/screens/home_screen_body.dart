// screens/home_screen_body.dart

import 'package:flutter/material.dart';

import '/widgets/latest_message_widget.dart';
import '/widgets/send_notification_button.dart';
import '/widgets/recent_messages_widget.dart';

class HomeScreenBody extends StatelessWidget {
  const HomeScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LatestMessageWidget(),
          const SizedBox(height: 20),
          SendNotificationButton(),
          const SizedBox(height: 20),
          const Text("Recent Messages:"),
          RecentMessagesWidget(),
        ],
      ),
    );
  }
}
