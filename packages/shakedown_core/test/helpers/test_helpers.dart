import 'package:flutter/foundation.dart';
import 'package:shakedown_core/services/device_service.dart';

class MockDeviceService extends ChangeNotifier implements DeviceService {
  bool _isTv = false;
  bool _isPwa = false;

  @override
  bool get isTv => _isTv;

  set isTv(bool value) {
    _isTv = value;
    notifyListeners();
  }

  @override
  bool get isMobile => false;

  @override
  bool get isDesktop => true;

  @override
  bool get isSafari => false;

  @override
  bool get isPwa => _isPwa;

  set isPwa(bool value) {
    _isPwa = value;
    notifyListeners();
  }

  @override
  String? get deviceName => 'Mock Device';

  @override
  bool get isLowEndTvDevice => false;

  @override
  Future<void> refresh() async {}
}
