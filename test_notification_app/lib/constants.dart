import 'dart:io';

final String baseURL = Platform.isIOS ? "http://localhost" : "http://10.0.2.2";
final String mqttBroker = Platform.isIOS ? "localhost" : "10.0.2.2";
const int mqttPort = 1883;
const bool enableTLS = false;

// const String baseURL = "https://192.168.178.33";
// const String mqttBroker = "192.168.178.33";
// const int mqttPort = 8883;
// const bool enableTLS = true;
