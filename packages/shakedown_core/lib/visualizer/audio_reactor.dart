/// Data class representing audio energy levels across frequency bands.
///
/// This is used by audio reactors to communicate frequency data to the
/// Screensaver visualizer for reactive animations.
class AudioEnergy {
  final double bass; // Low frequencies (20-250 Hz)
  final double mid; // Mid frequencies (250-4000 Hz)
  final double treble; // High frequencies (4000-20000 Hz)
  final double overall; // Overall energy level

  /// Whether a beat was detected in this frame (onset detection).
  final bool isBeat;

  /// 8-band frequency data for detailed EQ visualization.
  /// Bands: sub-bass, bass, low-mid, mid, upper-mid, presence, brilliance, air.
  final List<double> bands;

  const AudioEnergy({
    required this.bass,
    required this.mid,
    required this.treble,
    required this.overall,
    this.isBeat = false,
    this.bands = const [0, 0, 0, 0, 0, 0, 0, 0],
  });

  /// Create an AudioEnergy with all values set to zero (silence)
  const AudioEnergy.zero()
    : bass = 0.0,
      mid = 0.0,
      treble = 0.0,
      overall = 0.0,
      isBeat = false,
      bands = const [0, 0, 0, 0, 0, 0, 0, 0];

  @override
  String toString() {
    return 'AudioEnergy(bass: ${bass.toStringAsFixed(2)}, '
        'mid: ${mid.toStringAsFixed(2)}, '
        'treble: ${treble.toStringAsFixed(2)}, '
        'overall: ${overall.toStringAsFixed(2)}, '
        'isBeat: $isBeat)';
  }
}

/// Abstract interface for audio reactivity implementations.
///
/// Different platforms can provide different implementations:
/// - Android: Use Visualizer API for real-time FFT analysis
/// - Fallback: Use playback position heuristics
abstract class AudioReactor {
  /// Stream of audio energy data.
  /// Emits new values as audio data is analyzed.
  Stream<AudioEnergy> get energyStream;

  /// Start listening to audio data.
  void start();

  /// Stop listening to audio data.
  void stop();

  /// Update tuning configuration.
  void updateConfig({
    double? peakDecay,
    double? bassBoost,
    double? reactivityStrength,
    double? beatSensitivity,
  });

  /// Dispose of resources.
  void dispose();
}
