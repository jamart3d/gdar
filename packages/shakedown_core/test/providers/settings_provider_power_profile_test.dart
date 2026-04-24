import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test(
    'battery saver profile applies durable HTML5-like hybrid settings',
    () async {
      SharedPreferences.setMockInitialValues({'first_run_check_done': true});
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      provider.setWebPlaybackPowerProfile(WebPlaybackPowerProfile.batterySaver);

      expect(
        provider.webPlaybackPowerProfile,
        WebPlaybackPowerProfile.batterySaver,
      );
      expect(
        provider.resolvedWebPlaybackPowerSource,
        ResolvedWebPlaybackPowerSource.battery,
      );
      expect(provider.audioEngineMode, AudioEngineMode.hybrid);
      expect(provider.hybridHandoffMode, HybridHandoffMode.none);
      expect(provider.hybridBackgroundMode, HybridBackgroundMode.video);
      expect(provider.allowHiddenWebAudio, isFalse);
      expect(provider.preventSleep, isFalse);
      expect(provider.webPrefetchSeconds, 30);
      expect(prefs.getString('web_playback_power_profile'), 'batterySaver');
    },
  );

  test(
    'charging gapless profile applies immediate hybrid gapless settings',
    () async {
      SharedPreferences.setMockInitialValues({'first_run_check_done': true});
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      provider.setWebPlaybackPowerProfile(
        WebPlaybackPowerProfile.chargingGapless,
      );

      expect(
        provider.webPlaybackPowerProfile,
        WebPlaybackPowerProfile.chargingGapless,
      );
      expect(
        provider.resolvedWebPlaybackPowerSource,
        ResolvedWebPlaybackPowerSource.charging,
      );
      expect(provider.audioEngineMode, AudioEngineMode.hybrid);
      expect(provider.hybridHandoffMode, HybridHandoffMode.immediate);
      expect(provider.hybridBackgroundMode, HybridBackgroundMode.video);
      expect(provider.allowHiddenWebAudio, isTrue);
      expect(provider.preventSleep, isTrue);
      expect(provider.webPrefetchSeconds, 60);
    },
  );

  test('manual advanced engine changes switch profile to custom', () async {
    SharedPreferences.setMockInitialValues({'first_run_check_done': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs);

    provider.setWebPlaybackPowerProfile(
      WebPlaybackPowerProfile.chargingGapless,
    );
    provider.setHybridHandoffMode(HybridHandoffMode.boundary);

    expect(provider.webPlaybackPowerProfile, WebPlaybackPowerProfile.custom);
    expect(provider.hybridHandoffMode, HybridHandoffMode.boundary);
    expect(prefs.getString('web_playback_power_profile'), 'custom');
  });

  test(
    'persisted charging gapless profile resolves source on non-web without applying web defaults',
    () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'web_playback_power_profile': 'chargingGapless',
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(
        provider.webPlaybackPowerProfile,
        WebPlaybackPowerProfile.chargingGapless,
      );
      expect(
        provider.resolvedWebPlaybackPowerSource,
        ResolvedWebPlaybackPowerSource.charging,
      );
      expect(provider.audioEngineMode, AudioEngineMode.standard);
      expect(provider.preventSleep, isFalse);
    },
  );
}
