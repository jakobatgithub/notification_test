// utils/shared_preferences_util.dart

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  static Future<void> addMQTTMessage(String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messages = prefs.getStringList('receivedMQTTMessages') ?? [];
    messages.add(message);
    await prefs.setStringList('receivedMQTTMessages', messages);
  }

  static Future<Set<String>> loadMQTTMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('receivedMQTTMessages') ?? []).toSet();
  }
}
