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

  void removeDeviceById(int id) {
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void updateDevice(Device updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) {
      _devices[index] = updatedDevice;
      notifyListeners();
    }
  }

  void updateDeviceFields({
    required int deviceId,
    bool? active,
    String? lastStatus,
    String? lastConnectedAt,
  }) {
    final device = _findDeviceById(deviceId);
    if (device != null) {
      if (active != null) device.active = active;
      if (lastStatus != null) device.lastStatus = lastStatus;
      if (lastConnectedAt != null) device.lastConnectedAt = lastConnectedAt;
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

  Device? _findDeviceById(int id) {
    for (final device in _devices) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }
}
