import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';

class MQTTService {
  late MqttServerClient _client;
  Function(String)? onMessageReceived; // Callback function for UI updates

  MQTTService({this.onMessageReceived});

  Future<void> initializeMQTT() async {
    _client = MqttServerClient('broker.emqx.io', 'flutter_client');
    _client.port = 1883;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;

    try {
      await _client.connect();
      _client.subscribe("test/notifications", MqttQos.atMostOnce);

      // Listen for incoming messages
      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        if (messages != null && messages.isNotEmpty) {
          final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
          final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
          print("📩 MQTT Message Received: $payload");

          // Call UI update callback if defined
          if (onMessageReceived != null) {
            onMessageReceived!(payload);
          }
        }
      });
    } catch (e) {
      print("❌ MQTT Connection Failed: $e");
    }
  }

  void _onConnected() {
    print("✅ Connected to MQTT broker!");
  }

  void _onDisconnected() {
    print("⚠ Disconnected from MQTT broker.");
  }

  void _onSubscribed(String topic) {
    print("🔔 Subscribed to topic: $topic");
  }

  void publishMessage(String topic, String message) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      print("📤 Published: $message to $topic");
    } else {
      print("⚠ Cannot publish, MQTT is not connected.");
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
