import 'dart:async';

/// Defines the available easter eggs in the screensaver.
enum EasterEgg {
  woodstockMode, // Triggered at 4:20 PM
}

/// Helper class to detect easter egg triggers in the screensaver.
///
/// Currently supports:
/// - Woodstock Mode: Automatic trigger at 4:20 PM local time.
class EasterEggDetector {
  final Function(EasterEgg) onEasterEggTriggered;
  bool _everyHour;
  Timer? _timer;

  EasterEggDetector({required this.onEasterEggTriggered, bool everyHour = true})
    : _everyHour = everyHour {
    _scheduleNextTrigger();
  }

  void updateEveryHour(bool newEveryHour) {
    if (_everyHour != newEveryHour) {
      _everyHour = newEveryHour;
      _scheduleNextTrigger();
    }
  }

  void _scheduleNextTrigger() {
    _timer?.cancel();

    final now = DateTime.now();
    DateTime nextTrigger;

    if (_everyHour) {
      // Next target is exactly XX:20
      if (now.minute >= 20) {
        nextTrigger = DateTime(now.year, now.month, now.day, now.hour + 1, 20);
      } else {
        nextTrigger = DateTime(now.year, now.month, now.day, now.hour, 20);
      }
    } else {
      // Next target is 16:20 (4:20 PM)
      nextTrigger = DateTime(now.year, now.month, now.day, 16, 20);
      if (now.isAfter(nextTrigger) || now.isAtSameMomentAs(nextTrigger)) {
        nextTrigger = nextTrigger.add(const Duration(days: 1));
      }
    }

    final delay = nextTrigger.difference(now);
    _timer = Timer(delay, () {
      onEasterEggTriggered(EasterEgg.woodstockMode);
      // Reschedule for the next occurrence
      _scheduleNextTrigger();
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  /// Returns true if the current local time is the trigger time.
  static bool isWoodstockTime(bool everyHour) {
    final now = DateTime.now();
    if (everyHour) {
      return now.minute == 20;
    } else {
      return now.hour == 16 && now.minute == 20;
    }
  }
}
