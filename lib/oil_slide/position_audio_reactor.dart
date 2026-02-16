import 'dart:async';
import 'package:shakedown/oil_slide/oil_slide_audio_reactor.dart';

/// Fallback audio reactor that uses playback position heuristics.
///
/// This reactor doesn't analyze actual audio data, but instead generates
/// pseudo-reactive energy values based on playback position and timing.
/// It's used when the Android Visualizer API is not available.
class PositionAudioReactor implements OilSlideAudioReactor {
  final StreamController<AudioEnergy> _energyController =
      StreamController<AudioEnergy>.broadcast();

  Timer? _updateTimer;
  bool _isRunning = false;
  int _tickCount = 0;

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
  void dispose() {
    stop();
    _energyController.close();
  }

  /// Generate pseudo-reactive energy values using sine waves and randomness.
  /// This creates a visually pleasing effect even without real audio analysis.
  AudioEnergy _generateHeuristicEnergy() {
    final time = _tickCount / 30.0; // Convert ticks to seconds

    // Use different frequencies for different bands to create variation
    final bassPhase = time * 0.8;
    final midPhase = time * 1.2;
    final treblePhase = time * 1.8;

    // Generate smooth oscillating values with some randomness
    final bass = (_sine(bassPhase) * 0.5 + 0.5) * 0.7 + (_random() * 0.3);
    final mid = (_sine(midPhase) * 0.5 + 0.5) * 0.6 + (_random() * 0.4);
    final treble = (_sine(treblePhase) * 0.5 + 0.5) * 0.5 + (_random() * 0.5);
    final overall = (bass + mid + treble) / 3.0;

    return AudioEnergy(
      bass: bass.clamp(0.0, 1.0),
      mid: mid.clamp(0.0, 1.0),
      treble: treble.clamp(0.0, 1.0),
      overall: overall.clamp(0.0, 1.0),
    );
  }

  double _sine(double x) {
    // Simple sine approximation
    return (x % (2 * 3.14159265359)).toDouble();
  }

  double _random() {
    // Simple pseudo-random based on tick count
    return ((_tickCount * 1103515245 + 12345) % 100) / 100.0;
  }
}
