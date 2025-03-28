import 'package:flutter/material.dart';
import '../models/device.dart'; // make sure the model is in this path or update accordingly

class DeviceListWidget extends StatelessWidget {
  final List<Device> devices;

  const DeviceListWidget({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final color = device.active ? Colors.red : Colors.green;

        return ListTile(
          leading: Icon(Icons.device_hub, color: color),
          title: Text('User: ${device.user}', style: TextStyle(color: color)),
          subtitle: Text('Client ID: ${device.clientId}'),
        );
      },
    );
  }
}
