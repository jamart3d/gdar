import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService extends ChangeNotifier {
  static const _deviceChannel = MethodChannel('com.jamart3d.shakedown/device');

  bool _isTv = false;
  bool get isTv => _isTv;

  String? _deviceName;
  String? get deviceName => _deviceName;

  DeviceService({bool? initialIsTv}) {
    if (initialIsTv != null) {
      _isTv = initialIsTv;
    }
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      _deviceName = 'Web Browser';
      notifyListeners();
      return;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Source of truth for Android TV
        final bool? result = await _deviceChannel.invokeMethod<bool>('isTv');
        _isTv = result ?? false;

        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        _isTv = iosInfo.model.toLowerCase().contains('appletv');
        _deviceName = iosInfo.name;
      }
    } catch (e) {
      debugPrint('Error initializing DeviceService: $e');
    }

    notifyListeners();
  }

  /// Utility to refresh state if needed (e.g. on orientation change if that matters)
  Future<void> refresh() async {
    await _init();
  }
}
