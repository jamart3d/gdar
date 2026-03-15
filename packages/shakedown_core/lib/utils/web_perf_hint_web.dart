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
    final isLowCoreCount = cores > 0 && cores <= 4;

    return isMobileUa && isLowCoreCount;
  } catch (_) {
    return false;
  }
}
