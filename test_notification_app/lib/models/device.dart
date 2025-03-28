// models/device.dart

class Device {
  final int id;
  final int user;
  final String clientId;

  bool active;
  String lastStatus;
  String lastConnectedAt;

  Device({
    required this.id,
    required this.user,
    required this.clientId,
    required this.active,
    required this.lastStatus,
    required this.lastConnectedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      user: json['user'],
      clientId: json['client_id'],
      active: json['active'],
      lastStatus: json['last_status'],
      lastConnectedAt: json['last_connected_at'],
    );
  }
}
