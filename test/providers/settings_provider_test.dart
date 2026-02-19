import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/providers/settings_provider.dart';

void main() {
  late SettingsProvider settingsProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'first_run_check_done': true,
    });
    final prefs = await SharedPreferences.getInstance();
    settingsProvider = SettingsProvider(prefs);
  });

  group('SettingsProvider Shakedown Tween', () {
    test('initializes enableShakedownTween to true by default', () {
      expect(settingsProvider.enableShakedownTween, true);
    });

    test('toggleEnableShakedownTween toggles value and persists', () async {
      // Verify initial state
      expect(settingsProvider.enableShakedownTween, true);

      // Toggle OFF
      settingsProvider.toggleEnableShakedownTween();
      expect(settingsProvider.enableShakedownTween, false);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('enable_shakedown_tween'), false);

      // Toggle ON
      settingsProvider.toggleEnableShakedownTween();
      expect(settingsProvider.enableShakedownTween, true);
      expect(prefs.getBool('enable_shakedown_tween'), true);
    });

    test('initializes with true if saved in prefs', () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'enable_shakedown_tween': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(provider.enableShakedownTween, true);
    });
  });

  group('SettingsProvider Non-Random Playback', () {
    test('initializes nonRandom to false by default', () {
      expect(settingsProvider.nonRandom, false);
    });

    test('toggleNonRandom toggles value and persists', () async {
      // Verify initial state
      expect(settingsProvider.nonRandom, false);

      // Toggle ON
      settingsProvider.toggleNonRandom();
      expect(settingsProvider.nonRandom, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('non_random'), true);

      // Toggle OFF
      settingsProvider.toggleNonRandom();
      expect(settingsProvider.nonRandom, false);
      expect(prefs.getBool('non_random'), false);
    });

    test('initializes with true if saved in prefs', () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'non_random': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(provider.nonRandom, true);
    });
  });
  group('SettingsProvider Simple Random Legacy Icon', () {
    test('initializes simpleRandomIcon to false by default (internal only)',
        () {
      expect(settingsProvider.simpleRandomIcon, false);
    });

    test('toggleSimpleRandomIcon toggles value and persists', () async {
      // Verify initial state
      expect(settingsProvider.simpleRandomIcon, false);

      // Toggle ON
      settingsProvider.toggleSimpleRandomIcon();
      expect(settingsProvider.simpleRandomIcon, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('simple_random_icon'), true);

      // Toggle OFF
      settingsProvider.toggleSimpleRandomIcon();
      expect(settingsProvider.simpleRandomIcon, false);
      expect(prefs.getBool('simple_random_icon'), false);
    });
  });

  group('SettingsProvider Advanced Cache (Offline Buffering)', () {
    test('initializes offlineBuffering to false by default', () {
      expect(settingsProvider.offlineBuffering, false);
    });

    test('toggleOfflineBuffering toggles value and persists', () async {
      // Force initial state
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'offline_buffering': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(provider.offlineBuffering, false);

      // Toggle ON
      provider.toggleOfflineBuffering();
      expect(provider.offlineBuffering, true);
      expect(prefs.getBool('offline_buffering'), true);

      // Toggle OFF
      provider.toggleOfflineBuffering();
      expect(provider.offlineBuffering, false);
      expect(prefs.getBool('offline_buffering'), false);
    });

    test('initializes enableBufferAgent to true by default', () {
      expect(settingsProvider.enableBufferAgent, true);
    });

    test('toggleEnableBufferAgent toggles value and persists', () async {
      // Force initial state
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'enable_buffer_agent': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(provider.enableBufferAgent, true);

      // Toggle OFF
      provider.toggleEnableBufferAgent();
      expect(provider.enableBufferAgent, false);
      expect(prefs.getBool('enable_buffer_agent'), false);

      // Toggle ON
      provider.toggleEnableBufferAgent();
      expect(provider.enableBufferAgent, true);
      expect(prefs.getBool('enable_buffer_agent'), true);
    });
  });
  group('SettingsProvider UI Scale Sync', () {
    test('turning UI Scale ON enables abbreviations', () {
      // Setup: Scale OFF, Abbr OFF
      settingsProvider
          .toggleUiScale(); // First ensure it's OFF if default is ON
      if (settingsProvider.uiScale) settingsProvider.toggleUiScale();

      // Force OFF states to be sure
      if (settingsProvider.abbreviateDayOfWeek) {
        settingsProvider.toggleAbbreviateDayOfWeek();
      }
      if (settingsProvider.abbreviateMonth) {
        settingsProvider.toggleAbbreviateMonth();
      }

      expect(settingsProvider.uiScale, false);
      expect(settingsProvider.abbreviateDayOfWeek, false);
      expect(settingsProvider.abbreviateMonth, false);

      // Toggle ON
      settingsProvider.toggleUiScale();
      expect(settingsProvider.uiScale, true);
      expect(settingsProvider.abbreviateDayOfWeek, true);
      expect(settingsProvider.abbreviateMonth, true);
    });

    test('turning UI Scale OFF disables abbreviations', () {
      // Setup: Scale ON, Abbr ON
      if (!settingsProvider.uiScale) settingsProvider.toggleUiScale();

      expect(settingsProvider.uiScale, true);
      expect(settingsProvider.abbreviateDayOfWeek, true);
      expect(settingsProvider.abbreviateMonth, true);

      // Toggle OFF
      settingsProvider.toggleUiScale();
      expect(settingsProvider.uiScale, false);
      expect(settingsProvider.abbreviateDayOfWeek, false);
      expect(settingsProvider.abbreviateMonth, false);
    });
  });
  group('SettingsProvider Screensaver (Steal)', () {
    test('initializes with default values', () {
      expect(settingsProvider.useOilScreensaver, true);
      expect(settingsProvider.oilPalette, 'acid_green');
      expect(settingsProvider.oilEnableAudioReactivity, true);
    });

    test('toggles oil audio reactivity', () async {
      final initial = settingsProvider.oilEnableAudioReactivity;
      settingsProvider.toggleOilEnableAudioReactivity();
      expect(settingsProvider.oilEnableAudioReactivity, !initial);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('oil_enable_audio_reactivity'), !initial);
    });

    test('sets and persists oil palette', () async {
      await settingsProvider.setOilPalette('ocean');
      expect(settingsProvider.oilPalette, 'ocean');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('oil_palette'), 'ocean');
    });

    test(
        'sets and persists oil screensaver inactivity minutes (enforcing discrete values)',
        () async {
      // Test valid values
      settingsProvider.setOilScreensaverInactivityMinutes(1);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 1);

      settingsProvider.setOilScreensaverInactivityMinutes(15);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 15);

      settingsProvider.setOilScreensaverInactivityMinutes(5);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 5);

      // Verify persistence of last valid value
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('oil_screensaver_inactivity_minutes'), 5);

      // Test invalid values (should default to 5)
      settingsProvider.setOilScreensaverInactivityMinutes(10);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 5);

      settingsProvider.setOilScreensaverInactivityMinutes(30);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 5);

      settingsProvider.setOilScreensaverInactivityMinutes(0);
      expect(settingsProvider.oilScreensaverInactivityMinutes, 5);
    });
  });
}
