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

  /// Final detector score used to decide [isBeat] on the TV path.
  final double beatScore;

  /// Final detector threshold in the same units as [beatScore].
  final double beatThreshold;

  /// Final detector confidence, normalized to 0.0..1.0.
  final double beatConfidence;

  /// Final timing source for [isBeat], typically `VIS` or `PCM` on TV.
  final String? beatSource;

  /// Estimated pulse-grid tempo in beats per minute, when tracking is stable.
  final double? beatBpm;

  /// Recent inter-beat interval in milliseconds, when tracking is stable.
  final double? beatIbiMs;

  /// Current phase through the predicted beat interval, normalized to 0.0..1.0.
  final double? beatPhase;

  /// Milliseconds remaining until the next predicted beat window.
  final double? nextBeatMs;

  /// Confidence that the tracker has locked to a stable pulse grid.
  final double? beatGridConfidence;

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
  /// Index: 0=BASS, 1=MID, 2=BROAD, 3=ALL, 4=EMA, 5=TREB.
  /// Empty on web / fallback reactor.
  final List<bool> beatAlgos;

  /// Diagnostic per-algorithm score payload (0.0–3.0 in current TV path).
  /// Order matches [beatAlgos]: BASS, MID, BROAD, ALL, EMA, TREB.
  /// Empty on web / fallback reactor.
  final List<double> algoLevels;

  /// Raw detector input signal per algorithm before thresholding.
  /// Order matches [beatAlgos].
  final List<double> algoSignals;

  /// Baseline per algorithm used to compute [algoLevels].
  /// For mean-window variants this is the rolling mean; for `EMA` this is the
  /// EMA baseline. Order matches [beatAlgos].
  final List<double> algoBaselines;

  /// Threshold ratio per algorithm in score space.
  /// Example: `signal / baseline > thresholdRatio`.
  final List<double> algoThresholds;

  /// Index of the strongest current algorithm score, or null when no algorithm
  /// has a meaningful score yet.
  final int? winningAlgoId;

  /// Native Android audio session currently driving the visualizer, when known.
  final int? debugAudioSessionId;

  const AudioEnergy({
    required this.bass,
    required this.mid,
    required this.treble,
    required this.overall,
    this.isBeat = false,
    this.beatScore = 0.0,
    this.beatThreshold = 0.0,
    this.beatConfidence = 0.0,
    this.beatSource,
    this.beatBpm,
    this.beatIbiMs,
    this.beatPhase,
    this.nextBeatMs,
    this.beatGridConfidence,
    this.bands = const [0, 0, 0, 0, 0, 0, 0, 0],
    this.waveform = const [],
    this.waveformL = const [],
    this.waveformR = const [],
    this.beatAlgos = const [],
    this.algoLevels = const [],
    this.algoSignals = const [],
    this.algoBaselines = const [],
    this.algoThresholds = const [],
    this.winningAlgoId,
    this.debugAudioSessionId,
  });

  /// Create an AudioEnergy with all values set to zero (silence)
  const AudioEnergy.zero()
    : bass = 0.0,
      mid = 0.0,
      treble = 0.0,
      overall = 0.0,
      isBeat = false,
      beatScore = 0.0,
      beatThreshold = 0.0,
      beatConfidence = 0.0,
      beatSource = null,
      beatBpm = null,
      beatIbiMs = null,
      beatPhase = null,
      nextBeatMs = null,
      beatGridConfidence = null,
      bands = const [0, 0, 0, 0, 0, 0, 0, 0],
      waveform = const [],
      waveformL = const [],
      waveformR = const [],
      beatAlgos = const [],
      algoLevels = const [],
      algoSignals = const [],
      algoBaselines = const [],
      algoThresholds = const [],
      winningAlgoId = null,
      debugAudioSessionId = null;

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
    String? beatDetectorMode,
    double? beatSensitivity,
  });

  /// Dispose of resources.
  void dispose();
}
