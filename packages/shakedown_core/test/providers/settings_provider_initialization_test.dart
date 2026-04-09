import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/providers/settings_init/settings_defaults.dart';
import 'package:shakedown_core/providers/settings_init/settings_migrations.dart';
import 'package:shakedown_core/providers/settings_init/settings_pref_readers.dart';
import 'package:shakedown_core/providers/settings_init/settings_screensaver_pref_readers.dart';

void main() {
  group('settings defaults', () {
    test('prefers tv values over web values when both flags are true', () {
      expect(
        resolveBoolDefault(
          webVal: false,
          tvVal: true,
          phoneVal: false,
          isTv: true,
          isWeb: true,
        ),
        isTrue,
      );
    });

    test('returns web and phone string/int defaults for their platforms', () {
      expect(
        resolveStringDefault(
          webVal: 'web',
          tvVal: 'tv',
          phoneVal: 'phone',
          isTv: false,
          isWeb: true,
        ),
        'web',
      );
      expect(
        resolveIntDefault(
          webVal: 1,
          tvVal: 2,
          phoneVal: 3,
          isTv: false,
          isWeb: false,
        ),
        3,
      );
    });

    test('web playback messages default is off', () {
      expect(WebDefaults.showPlaybackMessages, isFalse);
    });
  });

  group('settings migrations', () {
    test('migrates legacy screensaver and handwriting prefs once', () async {
      SharedPreferences.setMockInitialValues({
        'use_screensaver': true,
        'use_handwriting_font': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final migrated = migrateLegacyCorePreferences(
        prefs,
        isTv: false,
        isWeb: false,
        useOilScreensaverKey: 'use_oil_screensaver',
        appFontKey: 'app_font',
      );

      expect(migrated.useOilScreensaver, isTrue);
      expect(migrated.appFont, 'caveat');
      expect(prefs.getBool('use_oil_screensaver'), isTrue);
      expect(prefs.getString('app_font'), 'caveat');
      expect(prefs.containsKey('use_screensaver'), isFalse);
      expect(prefs.containsKey('use_handwriting_font'), isFalse);
    });

    test('re-running legacy migration is idempotent', () async {
      SharedPreferences.setMockInitialValues({
        'use_screensaver': true,
        'use_handwriting_font': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final first = migrateLegacyCorePreferences(
        prefs,
        isTv: false,
        isWeb: false,
        useOilScreensaverKey: 'use_oil_screensaver',
        appFontKey: 'app_font',
      );
      final second = migrateLegacyCorePreferences(
        prefs,
        isTv: false,
        isWeb: false,
        useOilScreensaverKey: 'use_oil_screensaver',
        appFontKey: 'app_font',
      );

      expect(second.useOilScreensaver, first.useOilScreensaver);
      expect(second.appFont, first.appFont);
      expect(prefs.getBool('use_oil_screensaver'), isTrue);
      expect(prefs.getString('app_font'), 'caveat');
    });

    test('normalizes legacy oil banner font casing', () async {
      SharedPreferences.setMockInitialValues({'oil_banner_font': 'rock_salt'});
      final prefs = await SharedPreferences.getInstance();

      expect(
        loadOilBannerFontPreference(prefs, oilBannerFontKey: 'oil_banner_font'),
        'RockSalt',
      );
      expect(prefs.getString('oil_banner_font'), 'RockSalt');
    });
  });

  group('settings readers', () {
    test('uses platform defaults for prevent sleep', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(
        loadPreventSleepPreference(
          prefs,
          preventSleepKey: 'prevent_sleep',
          isTv: true,
          isWeb: false,
        ),
        TvDefaults.preventSleep,
      );
      expect(
        loadPreventSleepPreference(
          prefs,
          preventSleepKey: 'prevent_sleep',
          isTv: false,
          isWeb: true,
        ),
        DefaultSettings.preventSleep,
      );
      expect(
        loadPreventSleepPreference(
          prefs,
          preventSleepKey: 'prevent_sleep',
          isTv: false,
          isWeb: false,
        ),
        PhoneDefaults.preventSleep,
      );
    });

    test('uses platform defaults for oil performance level', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(
        loadOilPerformanceLevelPreference(
          prefs,
          oilPerformanceLevelKey: 'oil_performance_level',
          isTv: true,
          isWeb: false,
        ),
        TvDefaults.oilPerformanceLevel,
      );
      expect(
        loadOilPerformanceLevelPreference(
          prefs,
          oilPerformanceLevelKey: 'oil_performance_level',
          isTv: false,
          isWeb: false,
        ),
        DefaultSettings.oilPerformanceLevel,
      );
    });
  });
}
