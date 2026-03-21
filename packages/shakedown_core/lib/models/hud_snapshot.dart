// TODO(fetch-latency): add fetchTtfbMs field once gapless_audio_engine.js
// emits time-to-first-byte from performance.now() at fetch start → first chunk.
// Wire through: JS _emitState() → gapless_player_web.dart → AudioProvider
// → HudSnapshot, then add a NET chip + sparkline in dev_audio_hud.dart.

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

  // UI State Flags
  final bool hbActive;
  final bool hbNeeded;
  final bool heartbeatEnabledBySettings;
  final bool isPlaying;
  final bool isHandoffCountdown;

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
    required this.hbActive,
    required this.hbNeeded,
    required this.heartbeatEnabledBySettings,
    required this.isPlaying,
    required this.isHandoffCountdown,
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
    hbActive: false,
    hbNeeded: false,
    heartbeatEnabledBySettings: false,
    isPlaying: false,
    isHandoffCountdown: false,
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
    bool? hbActive,
    bool? hbNeeded,
    bool? heartbeatEnabledBySettings,
    bool? isPlaying,
    bool? isHandoffCountdown,
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
      hbActive: hbActive ?? this.hbActive,
      hbNeeded: hbNeeded ?? this.hbNeeded,
      heartbeatEnabledBySettings:
          heartbeatEnabledBySettings ?? this.heartbeatEnabledBySettings,
      isPlaying: isPlaying ?? this.isPlaying,
      isHandoffCountdown: isHandoffCountdown ?? this.isHandoffCountdown,
    );
  }
}
