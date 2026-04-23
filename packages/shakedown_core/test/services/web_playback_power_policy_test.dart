import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

void main() {
  group('resolveWebPlaybackPowerPolicy', () {
    test('auto falls back to battery-safe when charging state is unknown',
        () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.auto,
        detectedCharging: null,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.battery);
      expect(config.audioEngineMode, AudioEngineMode.hybrid);
      expect(config.handoffMode, HybridHandoffMode.none);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isFalse);
      expect(config.preventSleep, isFalse);
      expect(config.webPrefetchSeconds, 30);
      expect(config.applyEngineSettings, isTrue);
    });

    test('auto resolves to charging gapless when charging is detected', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.auto,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.charging);
      expect(config.audioEngineMode, AudioEngineMode.hybrid);
      expect(config.handoffMode, HybridHandoffMode.immediate);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isTrue);
      expect(config.preventSleep, isTrue);
      expect(config.webPrefetchSeconds, 60);
      expect(config.applyEngineSettings, isTrue);
    });

    test('batterySaver always resolves to battery-safe profile', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.batterySaver,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.battery);
      expect(config.handoffMode, HybridHandoffMode.none);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isFalse);
      expect(config.preventSleep, isFalse);
      expect(config.webPrefetchSeconds, 30);
    });

    test('chargingGapless always resolves to charging profile', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.chargingGapless,
        detectedCharging: false,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.charging);
      expect(config.handoffMode, HybridHandoffMode.immediate);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isTrue);
      expect(config.preventSleep, isTrue);
      expect(config.webPrefetchSeconds, 60);
    });

    test('custom returns a no-apply config', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.custom,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.custom);
      expect(config.applyEngineSettings, isFalse);
    });
  });
}
