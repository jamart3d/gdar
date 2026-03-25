import 'package:web/web.dart' as web;

bool isLikelyLowPowerWebDevice() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    final isMobileUa =
        ua.contains('mobi') ||
        ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ipad');

    final cores = web.window.navigator.hardwareConcurrency;
    final dpr = web.window.devicePixelRatio;
    // <= 2 cores: always low-power; <= 4 cores with low-DPI screen: budget device.
    // Avoids false-positiving modern quad-core phones (iPhone 14, mid-range Android)
    // which pair high core counts with high-DPI screens.
    final isLowCoreCount =
        cores > 0 && (cores <= 2 || (cores <= 4 && dpr < 2.0));

    return isMobileUa && isLowCoreCount;
  } catch (_) {
    return false;
  }
}

bool isSafariWeb() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('safari') &&
        !ua.contains('chrome') &&
        !ua.contains('chromium');
  } catch (_) {
    return false;
  }
}

bool isMobileWeb() {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('mobi') ||
        ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ipad');
  } catch (_) {
    return false;
  }
}
