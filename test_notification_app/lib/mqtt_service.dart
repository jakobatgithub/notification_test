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
    String? clientId = prefs.getString('mqtt_client_id');
    if (clientId == null) {
      clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('mqtt_client_id', clientId);
    }
    client = MqttServerClient(MQTT_BROKER, clientId);
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);
    client.onConnected = () => debugPrint('Connected to MQTT broker');
    client.onDisconnected = () => debugPrint('Disconnected from MQTT broker');
    client.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('Connection failed: $e');
      return;
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
