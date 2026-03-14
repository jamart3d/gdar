import 'dart:js_interop';
import 'package:web/web.dart' as web;

void vibrateWeb(int durationMs) {
  try {
    web.window.navigator.vibrate(durationMs.toJS);
  } catch (_) {
    // Browser may not support Vibration API or context is missing
  }
}
