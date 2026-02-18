/// Data class representing audio energy levels across frequency bands.
///
/// This is used by audio reactors to communicate frequency data to the
/// Screensaver visualizer for reactive animations.
class AudioEnergy {
  final double bass; // Low frequencies (20-250 Hz)
  final double mid; // Mid frequencies (250-4000 Hz)
  final double treble; // High frequencies (4000-20000 Hz)
  final double overall; // Overall energy level

  const AudioEnergy({
    required this.bass,
    required this.mid,
    required this.treble,
    required this.overall,
  });

  /// Create an AudioEnergy with all values set to zero (silence)
  const AudioEnergy.zero()
      : bass = 0.0,
        mid = 0.0,
        treble = 0.0,
        overall = 0.0;

  @override
  String toString() {
    return 'AudioEnergy(bass: ${bass.toStringAsFixed(2)}, '
        'mid: ${mid.toStringAsFixed(2)}, '
        'treble: ${treble.toStringAsFixed(2)}, '
        'overall: ${overall.toStringAsFixed(2)})';
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
  });

  /// Dispose of resources.
  void dispose();

  /// Factory constructor to create the appropriate reactor for the platform.
  ///
  /// On Android with audio output available, attempts to use VisualizerAudioReactor.
  /// Otherwise, falls back to PositionAudioReactor.
  ///
  /// Note: This is a placeholder. Actual implementation will be in a separate
  /// factory class to avoid circular dependencies.
  factory AudioReactor.create({
    required bool isAndroid,
    int? audioSessionId,
  }) {
    // This will be implemented in audio_reactor_factory.dart
    throw UnimplementedError('Use AudioReactorFactory.create() instead');
  }
}
