// screens/home_screen_body.dart

import 'package:flutter/material.dart';

import '/widgets/latest_message_widget.dart';
import '/widgets/send_notification_button.dart';
import '/widgets/recent_messages_widget.dart';
import '/widgets/device_list_widget.dart';

class HomeScreenBody extends StatelessWidget {
  const HomeScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 50),
            LatestMessageWidget(),
            const SizedBox(height: 20),
            SendNotificationButton(),
            const SizedBox(height: 20),
            const Text("Recent Messages:"),
            RecentMessagesWidget(),
            const SizedBox(height: 20),
            const Text("Devices:"),
            SizedBox(
              height: 300, // Adjust height as needed
              child: DeviceListWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
