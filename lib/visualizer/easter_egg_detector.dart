import 'dart:async';

/// Defines the available easter eggs in the screensaver.
enum EasterEgg {
  woodstockMode, // Triggered at 4:20 PM
}

/// Helper class to detect easter egg triggers in the screensaver.
///
/// Currently supports:
/// - Woodstock Mode: Automatic trigger at 4:20 PM.
class EasterEggDetector {
  final Function(EasterEgg) onEasterEggTriggered;
  Timer? _timer;

  EasterEggDetector({
    required this.onEasterEggTriggered,
  }) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isWoodstockTime()) {
        onEasterEggTriggered(EasterEgg.woodstockMode);
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  /// Checks if the current time is exactly 4:20 PM.
  static bool isWoodstockTime() {
    final now = DateTime.now();
    return now.hour == 16 && now.minute == 20; // 4:20 PM
  }
}
