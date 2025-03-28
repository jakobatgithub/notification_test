import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/mqtt_message.dart';

class MQTTService {
  late MqttServerClient client;
  final Function(String) onMessageReceived;

  MQTTService({required this.onMessageReceived});

  Future<void> initializeMQTT() async {
    await _retrieveMQTTTokenIfNeeded();

    final prefs = await SharedPreferences.getInstance();
    final mqttClientId = await _getOrCreateClientId(prefs);
    final mqttToken = prefs.getString('mqttToken');
    final userId = prefs.getString('userID');

    debugPrint("MQTT Token: $mqttToken, User ID: $userId");

    client = _createConfiguredClient(mqttClientId);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(mqttClientId)
        .authenticateAs(userId, mqttToken);

    client.connectionMessage = connMessage;

    await _tryConnect();

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      _subscribeToUserTopic(userId!);
      _listenForMessages();
    } else {
      debugPrint('❌ Connection failed: ${client.connectionStatus}');
    }
  }

  MqttServerClient _createConfiguredClient(String clientId) {
    final client = MqttServerClient.withPort(mqttBroker, clientId, mqttPort);
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.onBadCertificate = (dynamic cert) => true;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.setProtocolV311();
    client.onConnected = () => debugPrint("✅ Connected to MQTT Broker!");
    client.onDisconnected =
        () => debugPrint("❌ Disconnected from MQTT Broker!");
    client.onSubscribed =
        (String topic) => debugPrint("✅ Subscribed to $topic");
    return client;
  }

  Future<void> _tryConnect() async {
    try {
      await client.connect();
    } catch (e) {
      debugPrint("❌ Connection failed: $e");
      client.disconnect();
    }
  }

  void _subscribeToUserTopic(String userId) {
    client.subscribe("user/$userId/", MqttQos.atLeastOnce);
  }

  void _listenForMessages() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) async {
      final recMessage = c![0].payload as MqttPublishMessage;
      final payloadBytes = recMessage.payload.message;

      try {
        final payloadString = utf8.decode(payloadBytes);
        debugPrint('✅ Received MQTT message: $payloadString');

        final mqttMessage = MQTTMessage.fromJSONString(payloadString);
        _logDeviceEvent(mqttMessage);

        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        final message = _formatMessage(payload);

        await _storeReceivedMessage(message);
        onMessageReceived(message);
      } catch (e) {
        debugPrint('❌ Error decoding payload: $e');
      }
    });
  }

  void _logDeviceEvent(MQTTMessage msg) {
    if (msg.data is Map<String, dynamic>) {
      final event = msg.data['event'];
      final deviceId = msg.data['device_id'];
      if (event == 'device_connected') {
        debugPrint("Device $deviceId connected");
      } else if (event == 'device_disconnected') {
        debugPrint("Device $deviceId disconnected");
      }
    }
  }

  String _formatMessage(Map<String, dynamic> payload) {
    final msgId = payload['msg_id'].toString();
    final title = payload['title'] ?? "No message body";
    final body = payload['body'] ?? "No message body";
    return "msgID: $msgId, title: $title, body: $body";
  }

  Future<void> _storeReceivedMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList('receivedMQTTMessages') ?? [];
    messages.add(message);
    await prefs.setStringList('receivedMQTTMessages', messages);
  }

  Future<void> _retrieveMQTTTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('mqttToken') || !prefs.containsKey('userID')) {
      await retrieveMQTTToken();
    }
  }

  Future<String> _getOrCreateClientId(SharedPreferences prefs) async {
    String? id = prefs.getString('mqttClientID');
    if (id == null) {
      id = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('mqttClientID', id);
    }
    return id;
  }

  static Future<void> retrieveMQTTToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint('❌ No access token found');
      return;
    }

    final tokenURL = "$baseURL/emqx/token/";
    final response = await http.post(
      Uri.parse(tokenURL),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> tokens = jsonDecode(response.body);
      await prefs.setString('mqttToken', tokens['mqtt_token']);
      await prefs.setString('userID', tokens['user_id']);
      debugPrint(
        '🔐 MQTT Token: ${tokens['mqtt_token']}, User ID: ${tokens['user_id']}',
      );
    } else {
      debugPrint('❌ Failed to retrieve MQTT token: ${response.body}');
    }
  }

  void disconnect() {
    client.disconnect();
  }
}
