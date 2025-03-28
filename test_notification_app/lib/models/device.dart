// models/device.dart

class Device {
  final int user;
  final String clientId;

  String get deviceId => clientId;

  bool active;

  Device({required this.user, required this.clientId, required this.active});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      user: json['user'],
      clientId: json['client_id'],
      active: json['active'],
    );
  }
}
