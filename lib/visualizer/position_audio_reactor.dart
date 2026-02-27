import 'dart:async';
import 'dart:math';
import 'package:shakedown/visualizer/audio_reactor.dart';

/// Fallback audio reactor that uses playback position heuristics.
///
/// This reactor doesn't analyze actual audio data, but instead generates
/// pseudo-reactive energy values based on playback position and timing.
/// It's used when the Android Visualizer API is not available.
class PositionAudioReactor implements AudioReactor {
  final StreamController<AudioEnergy> _energyController =
      StreamController<AudioEnergy>.broadcast();

  final Random _rng = Random();
  Timer? _updateTimer;
  bool _isRunning = false;
  int _tickCount = 0;

  /// Track last bass value for simulated beat detection
  double _lastBass = 0.0;

  @override
  Stream<AudioEnergy> get energyStream => _energyController.stream;

  @override
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Update at ~30 FPS for smooth animation
    _updateTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _tickCount++;
      _energyController.add(_generateHeuristicEnergy());
    });
  }

  @override
  void stop() {
    _isRunning = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void updateConfig({
    double? peakDecay,
    double? bassBoost,
    double? reactivityStrength,
    double? beatSensitivity,
  }) {
    // Positioning reactor doesn't support these tuning knobs
  }

  @override
  void dispose() {
    stop();
    _energyController.close();
  }

  /// Generate pseudo-reactive energy values using sine waves and randomness.
  /// This creates a visually pleasing effect even without real audio analysis.
  AudioEnergy _generateHeuristicEnergy() {
    final time = _tickCount / 30.0; // Convert ticks to seconds

    // Use different frequencies for different bands to create variation
    final bass =
        ((sin(time * 0.8) * 0.5 + 0.5) * 0.7 + (_rng.nextDouble() * 0.3))
            .clamp(0.0, 1.0);
    final mid =
        ((sin(time * 1.2) * 0.5 + 0.5) * 0.6 + (_rng.nextDouble() * 0.4))
            .clamp(0.0, 1.0);
    final treble =
        ((sin(time * 1.8) * 0.5 + 0.5) * 0.5 + (_rng.nextDouble() * 0.5))
            .clamp(0.0, 1.0);
    final overall = ((bass + mid + treble) / 3.0).clamp(0.0, 1.0);

    // Simulated beat: detect when bass rises sharply
    final isBeat = bass > 0.6 && (bass - _lastBass) > 0.15;
    _lastBass = bass;

    // Generate 8-band simulated data with different phase offsets
    final bands = List<double>.generate(8, (i) {
      final phase = time * (0.6 + i * 0.25);
      return ((sin(phase) * 0.5 + 0.5) * 0.6 + (_rng.nextDouble() * 0.4))
          .clamp(0.0, 1.0);
    });

    return AudioEnergy(
      bass: bass,
      mid: mid,
      treble: treble,
      overall: overall,
      isBeat: isBeat,
      bands: bands,
    );
  }
}
