import 'dart:io';

final String mqttBroker = Platform.isIOS ? "localhost" : "10.0.2.2";

final String baseURL = Platform.isIOS ? "http://localhost" : "http://10.0.2.2";
const int mqttPort = 1883;
const bool enableTLS = false;

// Uncomment the following lines if you want to use secure MQTT connection
// final String baseURL = Platform.isIOS ? "https://localhost" : "https://10.0.2.2";
// const int mqttPort = 8883;
// const bool enableTLS = true;
