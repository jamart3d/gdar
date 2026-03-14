import 'dart:async';

/// Detects double-back press for exiting kiosk mode.
///
/// In kiosk mode, the screensaver should only exit when the user
/// presses the back button twice within a short time window (2 seconds).
class KioskExitDetector {
  DateTime? _lastBackPress;
  Timer? _resetTimer;

  static const Duration _doublePressWindow = Duration(seconds: 2);

  /// Check if a back press should trigger exit.
  ///
  /// Returns true if this is the second back press within the time window.
  /// Returns false if this is the first press or if too much time has elapsed.
  bool shouldExit() {
    final now = DateTime.now();

    if (_lastBackPress == null) {
      // First press
      _lastBackPress = now;
      _scheduleReset();
      return false;
    }

    final timeSinceLastPress = now.difference(_lastBackPress!);

    if (timeSinceLastPress <= _doublePressWindow) {
      // Second press within window - trigger exit
      _reset();
      return true;
    } else {
      // Too much time elapsed - treat as first press
      _lastBackPress = now;
      _scheduleReset();
      return false;
    }
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(_doublePressWindow, _reset);
  }

  void _reset() {
    _lastBackPress = null;
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  /// Clean up resources
  void dispose() {
    _resetTimer?.cancel();
  }
}
