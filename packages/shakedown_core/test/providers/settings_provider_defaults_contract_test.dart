import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';

/// Verifies that SettingsProvider applies correct per-platform defaults when
/// no user preferences have been saved (first install / fresh prefs).
///
/// Note: kIsWeb is a compile-time constant; web defaults cannot be unit-tested
/// here and require integration tests run on a browser platform.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SettingsProvider platform defaults — TV', () {
    late SettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'first_run_check_done': true});
      final prefs = await SharedPreferences.getInstance();
      provider = SettingsProvider(prefs, isTv: true);
    });

    test('hideTvScrollbars defaults to true on TV', () {
      expect(provider.hideTvScrollbars, true);
    });

    test('preventSleep defaults to true on TV', () {
      expect(provider.preventSleep, true);
    });

    test('showPlaybackMessages defaults to false on TV', () {
      expect(provider.showPlaybackMessages, false);
    });

    test('oilScreensaverMode defaults to steal on TV', () {
      expect(provider.oilScreensaverMode, 'steal');
    });

    test('activeAppFont always returns rock_salt on TV', () {
      expect(provider.activeAppFont, 'rock_salt');
    });

    test('performanceMode defaults to false on TV', () {
      expect(provider.performanceMode, false);
    });
  });

  group('SettingsProvider platform defaults — phone', () {
    late SettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'first_run_check_done': true});
      final prefs = await SharedPreferences.getInstance();
      provider = SettingsProvider(prefs); // isTv defaults to false
    });

    test('hideTvScrollbars defaults to false on phone', () {
      expect(provider.hideTvScrollbars, false);
    });

    test('preventSleep defaults to false on phone', () {
      expect(provider.preventSleep, false);
    });

    test('showPlaybackMessages defaults to true on phone', () {
      expect(provider.showPlaybackMessages, true);
    });

    test('useNeumorphism defaults to false on phone', () {
      expect(provider.useNeumorphism, false);
    });

    test('performanceMode defaults to false on phone', () {
      expect(provider.performanceMode, false);
    });

    test('oilScreensaverMode defaults to standard on phone', () {
      expect(provider.oilScreensaverMode, 'standard');
    });
  });

  group('AudioEnergy waveform field contract', () {
    test('waveform defaults to empty list', () {
      const e = AudioEnergy(bass: 0, mid: 0, treble: 0, overall: 0);
      expect(e.waveform, isEmpty);
    });

    test('AudioEnergy.zero() waveform is empty', () {
      expect(const AudioEnergy.zero().waveform, isEmpty);
    });

    test('waveform values are preserved', () {
      const e = AudioEnergy(
        bass: 0,
        mid: 0,
        treble: 0,
        overall: 0,
        waveform: [0.5, -0.5, 0.0],
      );
      expect(e.waveform, [0.5, -0.5, 0.0]);
    });
  });

  group('SettingsProvider platform defaults — EKG screensaver', () {
    late SettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'first_run_check_done': true});
      final prefs = await SharedPreferences.getInstance();
      provider = SettingsProvider(prefs, isTv: true);
    });

    test('oilEkgRadius defaults to 0.1', () {
      expect(provider.oilEkgRadius, 0.1);
    });

    test('oilEkgReplication defaults to 4', () {
      expect(provider.oilEkgReplication, 4);
    });

    test('oilEkgSpread defaults to 16.0', () {
      expect(provider.oilEkgSpread, 16.0);
    });

    test('oilBeatSensitivity defaults to 0.80', () {
      expect(provider.oilBeatSensitivity, 0.80);
    });
  });

  group('SettingsProvider platform defaults — user override wins', () {
    test('TV hideTvScrollbars can be overridden to false by user', () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'hide_tv_scrollbars': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs, isTv: true);

      expect(provider.hideTvScrollbars, false);
    });

    test('TV preventSleep can be overridden to false by user', () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'prevent_sleep': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs, isTv: true);

      expect(provider.preventSleep, false);
    });
  });
}
