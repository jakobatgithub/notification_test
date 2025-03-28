import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class DeviceListWidget extends StatelessWidget {
  const DeviceListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final devices = deviceProvider.devices;

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final color = device.active ? Colors.red : Colors.green;

        return ListTile(
          leading: Icon(Icons.device_hub, color: color),
          title: Text('User: ${device.userID}', style: TextStyle(color: color)),
          subtitle: Text('Client ID: ${device.clientId}'),
        );
      },
    );
  }
}
