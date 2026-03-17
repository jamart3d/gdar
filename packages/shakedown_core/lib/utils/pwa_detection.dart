import 'package:flutter/foundation.dart';
import 'package:shakedown_core/utils/web_perf_hint.dart';
import 'package:shakedown_core/utils/pwa_detection_stub.dart'
    if (dart.library.js_interop)
        'package:shakedown_core/utils/pwa_detection_web.dart'
    as impl;

enum WebRuntimeProfile {
  low,
  pwa,
  desk,
  web;

  String get label {
    switch (this) {
      case WebRuntimeProfile.low:
        return 'LOW';
      case WebRuntimeProfile.pwa:
        return 'PWA';
      case WebRuntimeProfile.desk:
        return 'DESK';
      case WebRuntimeProfile.web:
        return 'WEB';
    }
  }
}

WebRuntimeProfile detectWebRuntimeProfile() {
  if (!kIsWeb) return WebRuntimeProfile.web;
  if (isLikelyLowPowerWebDevice()) return WebRuntimeProfile.low;
  if (impl.isPwa()) return WebRuntimeProfile.pwa;
  if (_isDesktopWeb()) return WebRuntimeProfile.desk;
  return WebRuntimeProfile.web;
}

String detectedWebProfileLabel() => detectWebRuntimeProfile().label;

bool _isDesktopWeb() {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

