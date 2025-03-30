// providers/device_provider.dart

import 'package:flutter/material.dart';

import '/models/message.dart';

class MessageProvider with ChangeNotifier {
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void setMessages(List<Message> newMessages) {
    _messages
      ..clear()
      ..addAll(newMessages);
    notifyListeners();
  }
}
