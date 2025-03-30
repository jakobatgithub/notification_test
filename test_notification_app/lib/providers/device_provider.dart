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

  void addNewDevice({
    required int user,
    required String clientID,
    bool active = true,
  }) {
    final newDevice = Device(user: user, clientID: clientID, active: active);
    _devices.add(newDevice);
    notifyListeners();
  }

  void updateDeviceFields({required String clientID, bool? active}) {
    final device = getDeviceByClientId(clientID);
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

  Device? getDeviceByClientId(String clientID) {
    for (final device in _devices) {
      if (device.clientID == clientID) {
        return device;
      }
    }
    return null;
  }
}
