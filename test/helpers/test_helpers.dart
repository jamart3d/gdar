import 'package:flutter/foundation.dart';
import 'package:shakedown/services/device_service.dart';

class MockDeviceService extends ChangeNotifier implements DeviceService {
  bool _isTv = false;

  @override
  bool get isTv => _isTv;

  set isTv(bool value) {
    _isTv = value;
    notifyListeners();
  }

  @override
  String? get deviceName => 'Mock Device';

  @override
  Future<void> refresh() async {}
}
