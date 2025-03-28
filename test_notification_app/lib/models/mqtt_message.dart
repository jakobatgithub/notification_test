// models/mqtt_message.dart

import 'dart:convert';

class MQTTMessage {
  final String msgId;
  final String title;
  final String body;
  final dynamic data;

  MQTTMessage({
    required this.msgId,
    required this.title,
    required this.body,
    this.data,
  });

  factory MQTTMessage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    dynamic parsedData;
    if (rawData is String) {
      try {
        parsedData = jsonDecode(rawData);
      } catch (_) {
        parsedData = rawData; // leave it as string if decoding fails
      }
    } else {
      parsedData = rawData;
    }

    return MQTTMessage(
      msgId: json['msg_id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: parsedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {'msg_id': msgId, 'title': title, 'body': body, 'data': data};
  }

  /// Converts a JSON string into an MqttMessage object
  static MQTTMessage fromJSONString(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return MQTTMessage.fromJson(jsonMap);
  }

  /// Converts the MqttMessage object into a JSON string
  String toJSONString() {
    return jsonEncode(toJson());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MQTTMessage &&
          runtimeType == other.runtimeType &&
          msgId == other.msgId &&
          title == other.title &&
          body == other.body &&
          data == other.data;

  @override
  int get hashCode =>
      msgId.hashCode ^ title.hashCode ^ body.hashCode ^ data.hashCode;
}
