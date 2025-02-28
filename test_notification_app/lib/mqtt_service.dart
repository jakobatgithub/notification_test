import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'constants.dart';

class MQTTService {
  late MqttServerClient client;
  final Function(String) onMessageReceived;

  MQTTService({required this.onMessageReceived});

  Future<void> initializeMQTT() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? CLIENT_ID = prefs.getString('mqtt_client_id');
    if (CLIENT_ID == null) {
      CLIENT_ID = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('mqtt_client_id', CLIENT_ID);
    }

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
    client.setProtocolV311();  // Use MQTT v3.1.1 (compatible with most brokers)

    // Try connecting
    try {
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(CLIENT_ID);

      client.connectionMessage = connMessage;

      await client.connect();
    } catch (e) {
      print("❌ Connection failed: $e");
      client.disconnect();
    }

    client.subscribe(MQTT_TOPIC, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) async {
      final recMessage = c![0].payload as MqttPublishMessage;
      final payloadBytes = recMessage.payload.message;

      try {
        final payloadString = utf8.decode(payloadBytes);
        debugPrint('Received MQTT message: $payloadString');

        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        String msg_id = payload['msg_id'].toString();
        String title = payload['title'] ?? "No message body";
        String body = payload['body'] ?? "No message body";
        String message = "msg_id: $msg_id, title: $title, body: $body";

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> messages = prefs.getStringList('receivedMQTTMessages') ?? [];
        messages.add(message);
        await prefs.setStringList('receivedMQTTMessages', messages);

        onMessageReceived(message);
      } catch (e) {
        debugPrint('Error decoding payload: $e');
      }
    });
  }

  void disconnect() {
    client.disconnect();
  }
}
