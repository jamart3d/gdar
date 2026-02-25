import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService extends ChangeNotifier {
  static const _deviceChannel = MethodChannel('com.jamart3d.shakedown/device');

  bool _isTv = false;
  bool get isTv => _isTv;

  String? _deviceName;
  String? get deviceName => _deviceName;

  /// Returns true if the app is running on a mobile platform (Android or iOS),
  /// including mobile browsers when running on the web.
  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true if the app is running on a desktop platform (Windows, macOS, or Linux).
  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  DeviceService({bool? initialIsTv}) {
    if (initialIsTv != null) {
      _isTv = initialIsTv;
    }
    _init();
  }

  Future<void> _init() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceName = 'Web (${webInfo.browserName.name})';
        // On web, we don't have a reliable "isTv" check without custom logic,
        // but we can at least detect the browser.
        notifyListeners();
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Source of truth for Android TV
        final bool? result = await _deviceChannel.invokeMethod<bool>('isTv');
        _isTv = result ?? false;

        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _isTv = iosInfo.model.toLowerCase().contains('appletv');
        _deviceName = iosInfo.name;
      }
    } catch (e) {
      debugPrint('Error initializing DeviceService: $e');
      if (kIsWeb) _deviceName = 'Web Browser';
    }

    notifyListeners();
  }

  /// Utility to refresh state if needed (e.g. on orientation change if that matters)
  Future<void> refresh() async {
    await _init();
  }
}
