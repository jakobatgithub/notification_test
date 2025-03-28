import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/device.dart';
import 'dart:convert';

class DevicesService {
  static Future<List<Device>> getDevicesList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    if (accessToken == null) {
      debugPrint('❌ No access token found');
      return [];
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
      return rawList.map((json) => Device.fromJson(json)).toList();
    } else {
      debugPrint('❌ Get request failed with status ${response.statusCode}');
      return [];
    }
  }
}
