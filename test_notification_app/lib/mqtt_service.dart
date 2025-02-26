import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'constants.dart';

class MQTTService {
  late MqttServerClient client;
  final Function(String) onMessageReceived;

  MQTTService({required this.onMessageReceived});

  Future<void> initializeMQTT() async {
    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient(MQTT_BROKER, clientId);
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);
    client.onConnected = () => debugPrint('Connected to MQTT broker');
    client.onDisconnected = () => debugPrint('Disconnected from MQTT broker');
    client.autoReconnect = true;  // Automatically reconnect on disconnection

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('Connection failed: $e');
      return;
    }

    client.subscribe(MQTT_TOPIC, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMessage = c![0].payload as MqttPublishMessage;

      final payloadBytes = recMessage.payload.message;

      debugPrint('Received MQTT message: $payloadBytes');

      try {
        final payloadString = utf8.decode(payloadBytes);
        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        String msg_id = payload['msg_id'].toString();
        String title = payload['title'] ?? "No message body";
        String body = payload['body'] ?? "No message body";
        onMessageReceived("msg_id: $msg_id, title: $title, body: $body");
      } catch (e) {
        debugPrint('Error decoding payload: $e');
      }
    });
  }

  void disconnect() {
    client.disconnect();
  }
}
