import 'package:flutter/services.dart';
import 'package:shakedown/services/device_service.dart';

/// Centralized utility for haptic feedback.
/// Strictly respects the TV Platform Specification by gating all haptics
/// behind a TV check to ensure zero vibrations on TV devices.
class AppHaptics {
  /// Triggers a selection click haptic.
  static Future<void> selectionClick(DeviceService deviceService) async {
    if (deviceService.isTv) return;
    await HapticFeedback.selectionClick();
  }

  /// Triggers a light impact haptic.
  static Future<void> lightImpact(DeviceService deviceService) async {
    if (deviceService.isTv) return;
    await HapticFeedback.lightImpact();
  }

  /// Triggers a medium impact haptic.
  static Future<void> mediumImpact(DeviceService deviceService) async {
    if (deviceService.isTv) return;
    await HapticFeedback.mediumImpact();
  }

  /// Triggers a heavy impact haptic.
  static Future<void> heavyImpact(DeviceService deviceService) async {
    if (deviceService.isTv) return;
    await HapticFeedback.heavyImpact();
  }

  /// Triggers a vibrate haptic.
  static Future<void> vibrate(DeviceService deviceService) async {
    if (deviceService.isTv) return;
    await HapticFeedback.vibrate();
  }
}
