import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class MQTTService {
  late MqttServerClient client;
  final Function(String) onMessageReceived;

  MQTTService({required this.onMessageReceived});

  Future<void> initializeMQTT() async {
    retrieveMQTTToken();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? CLIENT_ID = prefs.getString('mqtt_client_id');
    if (CLIENT_ID == null) {
      CLIENT_ID = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('mqtt_client_id', CLIENT_ID);
    }

    String? mqttToken = prefs.getString('mqttToken');
    String? user_id = prefs.getString('user_id');
    print("MQTT Token: $mqttToken, User ID: $user_id");

    final client = MqttServerClient.withPort(MQTT_BROKER, CLIENT_ID, MQTT_PORT);

    // Enable logging to see connection issues
    client.logging(on: true);

    // Set keep-alive period
    client.keepAlivePeriod = 20;

    // Define connection callbacks
    client.onConnected = () => print("✅ Connected to MQTT Broker!");
    client.onDisconnected = () => print("❌ Disconnected from MQTT Broker!");
    client.onSubscribed = (String topic) => print("✅ Subscribed to $topic");

    // Set connection protocol
    client.setProtocolV311(); // Use MQTT v3.1.1 (compatible with most brokers)

    // Try connecting
    try {
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(CLIENT_ID)
          .authenticateAs(user_id, mqttToken);

      client.connectionMessage = connMessage;

      await client.connect();
    } catch (e) {
      print("❌ Connection failed: $e");
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe("user/$user_id/", MqttQos.atLeastOnce);

      client.updates!.listen((
        List<MqttReceivedMessage<MqttMessage?>>? c,
      ) async {
        final recMessage = c![0].payload as MqttPublishMessage;
        final payloadBytes = recMessage.payload.message;

        try {
          final payloadString = utf8.decode(payloadBytes);
          print('✅ Received MQTT message: $payloadString');

          final payload = jsonDecode(payloadString) as Map<String, dynamic>;
          String msg_id = payload['msg_id'].toString();
          String title = payload['title'] ?? "No message body";
          String body = payload['body'] ?? "No message body";
          String message = "msg_id: $msg_id, title: $title, body: $body";

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> messages =
              prefs.getStringList('receivedMQTTMessages') ?? [];
          messages.add(message);
          await prefs.setStringList('receivedMQTTMessages', messages);

          onMessageReceived(message);
        } catch (e) {
          print('❌ Error decoding payload: $e');
        }
      });
    } else {
      print('❌ Connection failed: ${client.connectionStatus}');
    }
  }

  static Future<void> retrieveMQTTToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('❌ No access token found');
      return;
    }

    String tokenURL = "$BASE_URL/api/mqtt-token/";
    final response = await http.get(
      Uri.parse(tokenURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> tokens = jsonDecode(response.body);
      String mqttToken = tokens['mqtt_token'];
      String user_id = tokens['user_id'];
      print('🔐 MQTT Token: $mqttToken, User ID: $user_id');

      await prefs.setString('mqttToken', mqttToken);
      await prefs.setString('user_id', user_id);
    } else {
      print('❌ Failed to retrieve MQTT token: ${response.body}');
    }
  }

  void disconnect() {
    client.disconnect();
  }
}
