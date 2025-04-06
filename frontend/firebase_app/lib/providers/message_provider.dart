// providers/message_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/models/message.dart';

class MessageProvider with ChangeNotifier {
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  MessageProvider() {
    _loadMessages();
  }

  void addMessage(Message message) {
    _messages.add(message);
    _saveMessages();
    notifyListeners();
  }

  void setMessages(List<Message> newMessages) {
    _messages
      ..clear()
      ..addAll(newMessages);
    _saveMessages();
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('messages', jsonList);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('messages') ?? [];
    _messages
      ..clear()
      ..addAll(
        jsonList.map((jsonStr) => Message.fromJson(jsonDecode(jsonStr))),
      );
    notifyListeners();
  }
}
