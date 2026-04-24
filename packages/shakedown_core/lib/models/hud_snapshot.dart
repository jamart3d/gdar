/// A processed snapshot of audio engine state and configuration for the HUD.
class HudSnapshot {
  final String engine; // ENG
  final String detectedProfile; // DET
  final String transition; // TX
  final String handoff; // HF
  final String background; // BG
  final String preset; // STB
  final String activeEngine; // AE
  final String heartbeat; // HB
  final String visibility; // V
  final String drift; // DFT
  final String prefetch; // PF
  final String processing; // PS
  final String buffered; // BUF
  final String headroom; // HD
  final String nextBuffered; // NX
  final String error; // E
  final String engineState; // ST
  final String signal; // SIG
  final String message; // MSG
  final String heartbeatBlocked; // HBB
  final String powerSource; // PWR

  // UI State Flags
  final bool hbActive;
  final bool hbNeeded;
  final bool heartbeatEnabledBySettings;
  final bool isPlaying;
  final bool isHandoffCountdown;

  // Fetch timing (web gapless engine only; null on native/HTML5/hybrid)
  final double? fetchTtfbMs;
  final bool fetchInFlight;

  // Track transition gap (ms between previous track end and current track start)
  final double? lastGapMs;

  // Advanced Web Audio / Hybrid Telemetry
  final int? scheduledIndex;
  final double? scheduledStartContextTime;
  final double? ctxCurrentTime;
  final double? outputLatencyMs;
  final double? lastDecodeMs;
  final double? lastConcatMs;
  final int? failedTrackCount;
  final int? workerTickCount;
  final int? sampleRate;
  final int? decodedCacheSize;
  final String? handoffState;
  final int? handoffAttemptCount;
  final int? lastHandoffPollCount;

  const HudSnapshot({
    required this.engine,
    required this.detectedProfile,
    required this.transition,
    required this.handoff,
    required this.background,
    required this.preset,
    required this.activeEngine,
    required this.heartbeat,
    required this.visibility,
    required this.drift,
    required this.prefetch,
    required this.processing,
    required this.buffered,
    required this.headroom,
    required this.nextBuffered,
    required this.error,
    required this.engineState,
    required this.signal,
    required this.message,
    required this.heartbeatBlocked,
    required this.powerSource,
    required this.hbActive,
    required this.hbNeeded,
    required this.heartbeatEnabledBySettings,
    required this.isPlaying,
    required this.isHandoffCountdown,
    this.fetchTtfbMs,
    this.fetchInFlight = false,
    this.lastGapMs,
    this.scheduledIndex,
    this.scheduledStartContextTime,
    this.ctxCurrentTime,
    this.outputLatencyMs,
    this.lastDecodeMs,
    this.lastConcatMs,
    this.failedTrackCount,
    this.workerTickCount,
    this.sampleRate,
    this.decodedCacheSize,
    this.handoffState,
    this.handoffAttemptCount,
    this.lastHandoffPollCount,
  });

  /// Initial empty snapshot to avoid null checks in UI.
  factory HudSnapshot.empty() => const HudSnapshot(
    engine: '--',
    detectedProfile: '--',
    transition: '--',
    handoff: '--',
    background: '--',
    preset: '--',
    activeEngine: '--',
    heartbeat: '--',
    visibility: '--',
    drift: '--',
    prefetch: '--',
    processing: '--',
    buffered: '--',
    headroom: '--',
    nextBuffered: '--',
    error: '--',
    engineState: '--',
    signal: '--',
    message: '--',
    heartbeatBlocked: '--',
    powerSource: '--',
    hbActive: false,
    hbNeeded: false,
    heartbeatEnabledBySettings: false,
    isPlaying: false,
    isHandoffCountdown: false,
    fetchTtfbMs: null,
    fetchInFlight: false,
    lastGapMs: null,
    scheduledIndex: null,
    scheduledStartContextTime: null,
    ctxCurrentTime: null,
    outputLatencyMs: null,
    lastDecodeMs: null,
    lastConcatMs: null,
    failedTrackCount: null,
    workerTickCount: null,
    sampleRate: null,
    decodedCacheSize: null,
    handoffState: null,
    handoffAttemptCount: null,
    lastHandoffPollCount: null,
  );

  Map<String, String> toMap() {
    return {
      'ENG': engine,
      'DET': detectedProfile,
      'TX': transition,
      'HF': handoff,
      'BG': background,
      'STB': preset,
      'AE': activeEngine,
      'HB': heartbeat,
      'V': visibility,
      'DFT': drift,
      'PF': prefetch,
      'PS': processing,
      'BUF': buffered,
      'HD': headroom,
      'NX': nextBuffered,
      'E': error,
      'ST': engineState,
      'SIG': signal,
      'MSG': message,
      'HBB': heartbeatBlocked,
      'PWR': powerSource,
    };
  }

  HudSnapshot copyWith({
    String? engine,
    String? detectedProfile,
    String? transition,
    String? handoff,
    String? background,
    String? preset,
    String? activeEngine,
    String? heartbeat,
    String? visibility,
    String? drift,
    String? prefetch,
    String? processing,
    String? buffered,
    String? headroom,
    String? nextBuffered,
    String? error,
    String? engineState,
    String? signal,
    String? message,
    String? heartbeatBlocked,
    String? powerSource,
    bool? hbActive,
    bool? hbNeeded,
    bool? heartbeatEnabledBySettings,
    bool? isPlaying,
    bool? isHandoffCountdown,
    double? fetchTtfbMs,
    bool? fetchInFlight,
    double? lastGapMs,
    int? scheduledIndex,
    double? scheduledStartContextTime,
    double? ctxCurrentTime,
    double? outputLatencyMs,
    double? lastDecodeMs,
    double? lastConcatMs,
    int? failedTrackCount,
    int? workerTickCount,
    int? sampleRate,
    int? decodedCacheSize,
    String? handoffState,
    int? handoffAttemptCount,
    int? lastHandoffPollCount,
  }) {
    return HudSnapshot(
      engine: engine ?? this.engine,
      detectedProfile: detectedProfile ?? this.detectedProfile,
      transition: transition ?? this.transition,
      handoff: handoff ?? this.handoff,
      background: background ?? this.background,
      preset: preset ?? this.preset,
      activeEngine: activeEngine ?? this.activeEngine,
      heartbeat: heartbeat ?? this.heartbeat,
      visibility: visibility ?? this.visibility,
      drift: drift ?? this.drift,
      prefetch: prefetch ?? this.prefetch,
      processing: processing ?? this.processing,
      buffered: buffered ?? this.buffered,
      headroom: headroom ?? this.headroom,
      nextBuffered: nextBuffered ?? this.nextBuffered,
      error: error ?? this.error,
      engineState: engineState ?? this.engineState,
      signal: signal ?? this.signal,
      message: message ?? this.message,
      heartbeatBlocked: heartbeatBlocked ?? this.heartbeatBlocked,
      powerSource: powerSource ?? this.powerSource,
      hbActive: hbActive ?? this.hbActive,
      hbNeeded: hbNeeded ?? this.hbNeeded,
      heartbeatEnabledBySettings:
          heartbeatEnabledBySettings ?? this.heartbeatEnabledBySettings,
      isPlaying: isPlaying ?? this.isPlaying,
      isHandoffCountdown: isHandoffCountdown ?? this.isHandoffCountdown,
      fetchTtfbMs: fetchTtfbMs ?? this.fetchTtfbMs,
      fetchInFlight: fetchInFlight ?? this.fetchInFlight,
      lastGapMs: lastGapMs ?? this.lastGapMs,
      scheduledIndex: scheduledIndex ?? this.scheduledIndex,
      scheduledStartContextTime:
          scheduledStartContextTime ?? this.scheduledStartContextTime,
      ctxCurrentTime: ctxCurrentTime ?? this.ctxCurrentTime,
      outputLatencyMs: outputLatencyMs ?? this.outputLatencyMs,
      lastDecodeMs: lastDecodeMs ?? this.lastDecodeMs,
      lastConcatMs: lastConcatMs ?? this.lastConcatMs,
      failedTrackCount: failedTrackCount ?? this.failedTrackCount,
      workerTickCount: workerTickCount ?? this.workerTickCount,
      sampleRate: sampleRate ?? this.sampleRate,
      decodedCacheSize: decodedCacheSize ?? this.decodedCacheSize,
      handoffState: handoffState ?? this.handoffState,
      handoffAttemptCount: handoffAttemptCount ?? this.handoffAttemptCount,
      lastHandoffPollCount: lastHandoffPollCount ?? this.lastHandoffPollCount,
    );
  }
}
