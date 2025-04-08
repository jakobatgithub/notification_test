// services/mqtt_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:async';

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

class MqttService {
  late final MqttServerClient _client;
  late final SharedPreferences _prefs;
  Timer? _refreshTimer;
  String? _ownClientId;

  MqttService();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureTokenAvailable();

    final clientId = await _getOrCreateClientId();
    final token = _prefs.getString('mqttAccessToken');
    final userId = _prefs.getString('user');
    _ownClientId = _prefs.getString('mqttClientID');

    if (token == null || userId == null) {
      debugPrint('❌ Missing MQTT credentials');
      return;
    }

    _client = _createClient(clientId, userId, token);
    await _connectClient();

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic("user/$userId/");
      _listenToMessages();
    } else {
      debugPrint('❌ MQTT connection failed: ${_client.connectionStatus}');
    }
  }

  Future<void> reconnect() async {
    debugPrint('🔄 Attempting MQTT reconnect...');
    final token = _prefs.getString('mqttAccessToken');
    final userId = _prefs.getString('user');
    final clientId = _prefs.getString('mqttClientID');

    if (token == null || userId == null || clientId == null) {
      debugPrint('❌ Missing credentials for MQTT reconnect');
      return;
    }

    await _connectClient();

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic("user/$userId/");
      _listenToMessages();
    }
  }

  MqttServerClient _createClient(String clientId, String userId, String token) {
    final client = MqttServerClient.withPort(mqttBroker, clientId, mqttPort);

    if (enableTLS) {
      client.secure = true;
      client.securityContext = SecurityContext.defaultContext;
    } else {
      client.secure = false;
    }

    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.setProtocolV311();

    client.onConnected = () => debugPrint("✅ Connected to MQTT broker");
    client.onDisconnected = () => debugPrint("❌ Disconnected from MQTT broker");
    client.onSubscribed = (topic) => debugPrint("✅ Subscribed to $topic");

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(userId, token);

    return client;
  }

  Future<void> _connectClient() async {
    try {
      await _client.connect();
    } catch (e) {
      debugPrint('❌ MQTT connect error: $e');
      _client.disconnect();
    }
  }

  void _subscribeToTopic(String topic) {
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void _listenToMessages() {
    _client.updates?.listen((
      List<MqttReceivedMessage<MqttMessage?>>? messages,
    ) async {
      if (messages == null || messages.isEmpty) return;

      final MqttPublishMessage mqttMessage =
          messages[0].payload as MqttPublishMessage;
      final payload = utf8.decode(mqttMessage.payload.message);

      debugPrint('✅ MQTT message received: $payload');

      try {
        final message = Message.fromJSONString(payload);
        if (_isSystemMessage(message)) {
          _handleSystemMessage(message);
        } else {
          _handleUserMessage(message);
        }
      } catch (e) {
        debugPrint('❌ Payload decoding error: $e');
      }
    });
  }

  bool _isSystemMessage(Message msg) => msg.title.isEmpty && msg.body.isEmpty;

  void _handleSystemMessage(Message message) {
    final data = message.data;
    if (data is! Map<String, dynamic> || !data.containsKey('event')) return;
    _processDeviceEvent(data);
  }

  void _processDeviceEvent(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final event = data['event'];
    final clientId = data['client_id'];

    if (clientId is! String || clientId == _ownClientId) return;

    switch (event) {
      case 'new_device_connected':
        final userId = data['user'];
        if (userId is int &&
            deviceProvider.getDeviceByClientId(clientId) == null) {
          deviceProvider.addNewDevice(
            user: userId,
            clientID: clientId,
            active: true,
          );
        }
        break;
      case 'device_connected':
      case 'device_disconnected':
        final isDisconnect = event == 'device_disconnected';
        deviceProvider.updateDeviceFields(
          clientID: clientId,
          active: !isDisconnect,
        );
        debugPrint("🔄 Device $clientId set to active = ${!isDisconnect}");
        break;
      default:
        break;
    }
  }

  void _handleUserMessage(Message message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    messageProvider.addMessage(message);
  }

  Future<void> _ensureTokenAvailable() async {
    if (!_prefs.containsKey('mqttAccessToken') ||
        !_prefs.containsKey('mqttRefreshToken') ||
        !_prefs.containsKey('user')) {
      await _retrieveMqttToken();
    }

    final token = _prefs.getString('mqttAccessToken');
    if (token != null) {
      _scheduleTokenRefresh(token);
    }
  }

  Future<String> _getOrCreateClientId() async {
    final existingId = _prefs.getString('mqttClientID');
    if (existingId != null) return existingId;

    final newId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString('mqttClientID', newId);
    return newId;
  }

  Future<void> _retrieveMqttToken() async {
    final accessToken = _prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint('❌ No access token found for MQTT token retrieval');
      return;
    }

    final response = await http.post(
      Uri.parse("$baseURL/emqx/token/"),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Token $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final mqttAccessToken = data['mqtt_access_token'];
      final mqttRefreshToken = data['mqtt_refresh_token'];
      final userId = data['user_id'];

      if (mqttAccessToken is String &&
          mqttRefreshToken is String &&
          userId is String) {
        await _prefs.setString('mqttAccessToken', mqttAccessToken);
        await _prefs.setString('mqttRefreshToken', mqttRefreshToken);
        await _prefs.setString('user', userId);
        debugPrint(
          '🔐 MQTT Token acquired: $mqttAccessToken for user: $userId',
        );
      } else {
        debugPrint('❌ Missing keys in MQTT token response: $data');
      }
    } else {
      debugPrint('❌ Failed to retrieve MQTT token: ${response.body}');
    }
  }

  void _scheduleTokenRefresh(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      final payloadBase64 = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      final payloadMap = jsonDecode(payloadString);

      final exp = payloadMap['exp'];
      if (exp == null) return;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final refreshAt = expiry.subtract(const Duration(minutes: 1));
      final durationUntilRefresh = refreshAt.difference(DateTime.now());

      if (durationUntilRefresh.isNegative) {
        _refreshMqttToken(); // Already close to expiration
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = Timer(durationUntilRefresh, _refreshMqttToken);
        debugPrint(
          '⏳ MQTT access token will refresh in: $durationUntilRefresh',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule MQTT token refresh: $e');
    }
  }

  Future<void> _refreshMqttToken() async {
    final mqttRefreshToken = _prefs.getString('mqttRefreshToken');
    final accessToken = _prefs.getString('accessToken');

    if (mqttRefreshToken == null) {
      debugPrint('❌ No refresh token available for MQTT token refresh');
      return;
    }

    final response = await http.post(
      Uri.parse('$baseURL/emqx/token/refresh/'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Token $accessToken',
      },
      body: jsonEncode({'refresh': mqttRefreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['mqtt_access_token'];
      if (newAccessToken is String) {
        await _prefs.setString('mqttAccessToken', newAccessToken);
        debugPrint('🔁 MQTT token refreshed');
        _scheduleTokenRefresh(newAccessToken);
      } else {
        debugPrint('❌ Invalid refresh response: $data');
      }
    } else {
      debugPrint('❌ MQTT token refresh failed: ${response.body}');
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
