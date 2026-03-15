import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/device_service.dart';
import 'web_haptics_stub.dart' if (dart.library.js_interop) 'web_haptics.dart';

/// Centralized utility for haptic feedback.
/// Strictly respects the TV Platform Specification by gating all haptics
/// behind a TV check to ensure zero vibrations on TV devices.
class AppHaptics {
  /// Internal helper to skip haptics on genuine TV platforms.
  /// Allows haptics on PWAs even if [force_tv] is active, as they remain touch devices.
  static bool _shouldSkip(DeviceService deviceService) {
    // If it's a PWA, we allow haptics even if isTv is true (forced for layout testing).
    if (kIsWeb && deviceService.isPwa) return false;
    return deviceService.isTv;
  }

  /// Triggers a selection click haptic.
  static Future<void> selectionClick(
    DeviceService deviceService, {
    bool enabled = true,
  }) async {
    if (!enabled || _shouldSkip(deviceService)) return;

    if (kIsWeb) {
      _vibrateWeb(20); // Subtle tick, increased for PWA visibility
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  /// Triggers a light impact haptic.
  static Future<void> lightImpact(
    DeviceService deviceService, {
    bool enabled = true,
  }) async {
    if (!enabled || _shouldSkip(deviceService)) return;

    if (kIsWeb) {
      _vibrateWeb(20); // Increased from 15ms for better perceptibility
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Triggers a medium impact haptic.
  static Future<void> mediumImpact(
    DeviceService deviceService, {
    bool enabled = true,
  }) async {
    if (!enabled || _shouldSkip(deviceService)) return;

    if (kIsWeb) {
      _vibrateWeb(40); // Increased from 30ms
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Triggers a heavy impact haptic.
  static Future<void> heavyImpact(
    DeviceService deviceService, {
    bool enabled = true,
  }) async {
    if (!enabled || _shouldSkip(deviceService)) return;

    if (kIsWeb) {
      _vibrateWeb(70); // Increased from 50ms
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Triggers a vibrate haptic.
  static Future<void> vibrate(
    DeviceService deviceService, {
    bool enabled = true,
  }) async {
    if (!enabled || _shouldSkip(deviceService)) return;

    if (kIsWeb) {
      _vibrateWeb(120); // Increased from 100ms
    } else {
      await HapticFeedback.vibrate();
    }
  }

  /// Directly calls the Web Vibration API for more robust feedback on Mobile Web.
  static void _vibrateWeb(int durationMs) {
    vibrateWeb(durationMs);
  }
}
