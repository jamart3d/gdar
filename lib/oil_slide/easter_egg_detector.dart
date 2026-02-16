import 'package:flutter/services.dart';

/// Detects easter egg input sequences.
///
/// Supports:
/// - Konami Code: ↑↑↓↓←→←→BA
/// - Woodstock Mode: Triggered at 4:20 PM
class EasterEggDetector {
  final List<LogicalKeyboardKey> _inputSequence = [];
  final void Function(EasterEgg) onEasterEggTriggered;

  static const List<LogicalKeyboardKey> _konamiCode = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];

  static const Duration _sequenceTimeout = Duration(seconds: 3);
  DateTime _lastInputTime = DateTime.now();

  EasterEggDetector({required this.onEasterEggTriggered});

  /// Process a key event and check for easter egg sequences
  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();

    // Reset sequence if too much time has passed
    if (now.difference(_lastInputTime) > _sequenceTimeout) {
      _inputSequence.clear();
    }

    _lastInputTime = now;
    _inputSequence.add(event.logicalKey);

    // Keep sequence length manageable
    if (_inputSequence.length > _konamiCode.length) {
      _inputSequence.removeAt(0);
    }

    // Check for Konami code
    if (_inputSequence.length == _konamiCode.length) {
      bool matches = true;
      for (int i = 0; i < _konamiCode.length; i++) {
        if (_inputSequence[i] != _konamiCode[i]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        _inputSequence.clear();
        onEasterEggTriggered(EasterEgg.konamiCode);
      }
    }
  }

  /// Check if current time is Woodstock time (4:20)
  static bool isWoodstockTime() {
    final now = DateTime.now();
    return now.hour == 16 && now.minute == 20; // 4:20 PM
  }
}

/// Available easter eggs
enum EasterEgg {
  konamiCode,
  woodstockMode,
}
