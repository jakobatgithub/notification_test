// providers/device_provider.dart

import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceProvider with ChangeNotifier {
  final List<Device> _devices = [];

  List<Device> get devices => _devices;

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void updateDeviceFields({required String deviceId, bool? active}) {
    final device = getDeviceByClientId(deviceId);
    if (device != null) {
      if (active != null) device.active = active;
      notifyListeners();
    }
  }

  void setDevices(List<Device> newDevices) {
    _devices
      ..clear()
      ..addAll(newDevices);
    notifyListeners();
  }

  Device? getDeviceByClientId(String clientId) {
    for (final device in _devices) {
      if (device.clientId == clientId) {
        return device;
      }
    }
    return null;
  }

  void createDevice({
    required int user,
    required String clientId,
    bool active = true,
  }) {
    final newDevice = Device(user: user, clientId: clientId, active: active);
    _devices.add(newDevice);
    notifyListeners();
  }
}
