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

  /// Raw PCM waveform samples, downsampled to 256 points, range -1.0..1.0.
  /// Empty when oscilloscope capture is unavailable (web, fallback reactor).
  final List<double> waveform;

  /// Stereo left-channel PCM, 256 points, range -1.0..1.0.
  /// Non-empty only on TV when AudioPlaybackCapture is active.
  /// Empty on web/mobile/fallback — VU meter falls back to fake-stereo FFT bands.
  final List<double> waveformL;

  /// Stereo right-channel PCM, 256 points, range -1.0..1.0.
  /// Non-empty only on TV when AudioPlaybackCapture is active.
  final List<double> waveformR;

  /// Results from 6 parallel beat-detection algorithms (beat_debug mode).
  /// Index: 0=NARROW, 1=KICK, 2=FULL, 3=EMA, 4=KICK+, 5=LONG.
  /// Empty on web / fallback reactor.
  final List<bool> beatAlgos;

  /// Normalised flux/mean ratio per algorithm (0.0–3.0).
  /// 1.0 = at mean, >1.66 = main threshold, >1.1 = KICK+ threshold.
  /// Empty on web / fallback reactor.
  final List<double> algoLevels;

  const AudioEnergy({
    required this.bass,
    required this.mid,
    required this.treble,
    required this.overall,
    this.isBeat = false,
    this.bands = const [0, 0, 0, 0, 0, 0, 0, 0],
    this.waveform = const [],
    this.waveformL = const [],
    this.waveformR = const [],
    this.beatAlgos = const [],
    this.algoLevels = const [],
  });

  /// Create an AudioEnergy with all values set to zero (silence)
  const AudioEnergy.zero()
    : bass = 0.0,
      mid = 0.0,
      treble = 0.0,
      overall = 0.0,
      isBeat = false,
      bands = const [0, 0, 0, 0, 0, 0, 0, 0],
      waveform = const [],
      waveformL = const [],
      waveformR = const [],
      beatAlgos = const [],
      algoLevels = const [];

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
  Future<void> start();

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
