// services/devices_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '/constants.dart';
import '/models/device.dart';
import '/providers/device_provider.dart';

class DevicesService {
  static Future<void> loadDevicesIntoProvider(BuildContext context) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    String? ownClientId = prefs.getString('mqttClientID');

    if (accessToken == null) {
      debugPrint('❌ No access token found');
      return;
    }

    final response = await http.get(
      Uri.parse("$baseURL/emqx/devices/"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      final List<Device> allDevices =
          rawList.map((json) => Device.fromJson(json)).toList();

      final filteredDevices =
          allDevices.where((device) => device.clientID != ownClientId).toList();

      debugPrint("📱 Own client ID: $ownClientId");
      debugPrint("🧹 Devices after filtering: ${filteredDevices.length}");

      deviceProvider.setDevices(filteredDevices);
    } else {
      debugPrint('❌ Get request failed with status ${response.statusCode}');
    }
  }
}
