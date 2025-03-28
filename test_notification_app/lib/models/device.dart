// models/device.dart

class Device {
  final int userID;
  final String clientId;

  String get deviceId => clientId;

  bool active;

  Device({required this.userID, required this.clientId, required this.active});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      userID: json['userID'],
      clientId: json['client_id'],
      active: json['active'],
    );
  }
}
