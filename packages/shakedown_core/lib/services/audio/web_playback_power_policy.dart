import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

enum WebPlaybackPowerProfile {
  auto,
  batterySaver,
  chargingGapless,
  custom;

  static WebPlaybackPowerProfile fromString(String? value) {
    return WebPlaybackPowerProfile.values.firstWhere(
      (profile) => profile.name == value,
      orElse: () => WebPlaybackPowerProfile.auto,
    );
  }
}

enum ResolvedWebPlaybackPowerSource { battery, charging, custom }

class WebPlaybackPowerPolicyConfig {
  const WebPlaybackPowerPolicyConfig({
    required this.resolvedSource,
    required this.audioEngineMode,
    required this.handoffMode,
    required this.backgroundMode,
    required this.allowHiddenWebAudio,
    required this.preventSleep,
    required this.webPrefetchSeconds,
    required this.applyEngineSettings,
  });

  final ResolvedWebPlaybackPowerSource resolvedSource;
  final AudioEngineMode? audioEngineMode;
  final HybridHandoffMode? handoffMode;
  final HybridBackgroundMode? backgroundMode;
  final bool? allowHiddenWebAudio;
  final bool? preventSleep;
  final int? webPrefetchSeconds;
  final bool applyEngineSettings;
}

WebPlaybackPowerPolicyConfig resolveWebPlaybackPowerPolicy({
  required WebPlaybackPowerProfile profile,
  required bool? detectedCharging,
}) {
  switch (profile) {
    case WebPlaybackPowerProfile.custom:
      return const WebPlaybackPowerPolicyConfig(
        resolvedSource: ResolvedWebPlaybackPowerSource.custom,
        audioEngineMode: null,
        handoffMode: null,
        backgroundMode: null,
        allowHiddenWebAudio: null,
        preventSleep: null,
        webPrefetchSeconds: null,
        applyEngineSettings: false,
      );
    case WebPlaybackPowerProfile.chargingGapless:
      return _chargingGaplessConfig;
    case WebPlaybackPowerProfile.batterySaver:
      return _batterySaverConfig;
    case WebPlaybackPowerProfile.auto:
      return detectedCharging == true
          ? _chargingGaplessConfig
          : _batterySaverConfig;
  }
}

const _batterySaverConfig = WebPlaybackPowerPolicyConfig(
  resolvedSource: ResolvedWebPlaybackPowerSource.battery,
  audioEngineMode: AudioEngineMode.hybrid,
  handoffMode: HybridHandoffMode.none,
  backgroundMode: HybridBackgroundMode.video,
  allowHiddenWebAudio: false,
  preventSleep: false,
  webPrefetchSeconds: 30,
  applyEngineSettings: true,
);

const _chargingGaplessConfig = WebPlaybackPowerPolicyConfig(
  resolvedSource: ResolvedWebPlaybackPowerSource.charging,
  audioEngineMode: AudioEngineMode.hybrid,
  handoffMode: HybridHandoffMode.immediate,
  backgroundMode: HybridBackgroundMode.video,
  allowHiddenWebAudio: true,
  preventSleep: true,
  webPrefetchSeconds: 60,
  applyEngineSettings: true,
);
