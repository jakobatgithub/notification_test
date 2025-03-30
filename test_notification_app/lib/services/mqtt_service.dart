// services/mqtt_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '/services/navigation_service.dart';
import '/providers/device_provider.dart';
import '/providers/message_provider.dart';
import '/models/message.dart';
import '/constants.dart';

class MQTTService {
  late MqttServerClient client;
  final Function(String) onMessageReceived;

  MQTTService({required this.onMessageReceived});

  Future<void> initializeMQTT() async {
    await _retrieveMQTTTokenIfNeeded();

    final prefs = await SharedPreferences.getInstance();
    final mqttClientId = await _getOrCreateClientId(prefs);
    final mqttToken = prefs.getString('mqttToken');
    final userId = prefs.getString('user');

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

  MqttServerClient _createConfiguredClient(String clientID) {
    final client = MqttServerClient.withPort(mqttBroker, clientID, mqttPort);
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

        final mqttMessage = Message.fromJSONString(payloadString);

        if (_isDataMessage(mqttMessage)) {
          _handleDataMessage(mqttMessage);
        } else {
          _handleDisplayMessage(mqttMessage);
        }
      } catch (e) {
        debugPrint('❌ Error decoding payload: $e');
      }
    });
  }

  bool _isDataMessage(Message msg) {
    if (msg.title == '' && msg.body == '') {
      return true;
    } else {
      return false;
    }
  }

  void _handleDataMessage(Message mqttMessage) {
    final data = mqttMessage.data;
    if (data is! Map<String, dynamic>) return;

    if (data.containsKey('event')) {
      _handleDeviceEvent(data);
    }
  }

  void _handleDeviceEvent(Map<String, dynamic> data) {
    final event = data['event'];
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    if (event == 'new_device_connected') {
      final newClientID = data['client_id'];
      final user = data['user'] as int;
      if (newClientID is! String) return;

      // Prevent duplicate devices based on clientID
      final existing = deviceProvider.getDeviceByClientId(newClientID);
      if (existing != null) return;

      deviceProvider.addNewDevice(
        user: user,
        clientID: newClientID,
        active: true,
      );
      return;
    }

    if (event != 'device_connected' && event != 'device_disconnected') return;

    final clientID = data['client_id'];
    if (clientID is! String) return;

    final isDisconnect = event == 'device_disconnected';

    debugPrint("Update Device $clientID to active = ${!isDisconnect}");
    deviceProvider.updateDeviceFields(
      clientID: clientID,
      active: !isDisconnect,
    );
  }

  void _handleDisplayMessage(Message message) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    messageProvider.addMessage(message);
  }

  Future<void> _retrieveMQTTTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('mqttToken') || !prefs.containsKey('user')) {
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
      await prefs.setString('user', tokens['user_id']);
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
