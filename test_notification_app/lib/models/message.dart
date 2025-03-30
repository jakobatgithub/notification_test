// models/mqtt_message.dart

import 'dart:convert';

class Message {
  final String msgId;
  final String title;
  final String body;
  final dynamic data;

  Message({
    required this.msgId,
    required this.title,
    required this.body,
    this.data,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
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

    return Message(
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
  static Message fromJSONString(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return Message.fromJson(jsonMap);
  }

  /// Converts the MqttMessage object into a JSON string
  String toJSONString() {
    return jsonEncode(toJson());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          msgId == other.msgId &&
          title == other.title &&
          body == other.body &&
          data == other.data;

  @override
  int get hashCode =>
      msgId.hashCode ^ title.hashCode ^ body.hashCode ^ data.hashCode;
}
