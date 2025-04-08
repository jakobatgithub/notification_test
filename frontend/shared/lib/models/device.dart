// models/device.dart

class Device {
  final int user;
  final String clientID;

  bool active;

  Device({required this.user, required this.clientID, required this.active});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      user: json['user'],
      clientID: json['client_id'],
      active: json['active'],
    );
  }
}
