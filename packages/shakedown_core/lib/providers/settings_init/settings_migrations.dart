import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/providers/settings_init/settings_defaults.dart';

class LegacyCoreMigrationResult {
  const LegacyCoreMigrationResult({
    required this.useOilScreensaver,
    required this.appFont,
  });

  final bool useOilScreensaver;
  final String appFont;
}

LegacyCoreMigrationResult migrateLegacyCorePreferences(
  SharedPreferences prefs, {
  required bool isTv,
  required bool isWeb,
  required String useOilScreensaverKey,
  required String appFontKey,
}) {
  final defaultScreensaver = resolveBoolDefault(
    webVal: WebDefaults.useOilScreensaver,
    tvVal: DefaultSettings.useOilScreensaver,
    phoneVal: DefaultSettings.useOilScreensaver,
    isTv: isTv,
    isWeb: isWeb,
  );

  late bool useOilScreensaver;
  if (prefs.containsKey('use_screensaver')) {
    final oldEnabled = prefs.getBool('use_screensaver') ?? true;
    useOilScreensaver = defaultScreensaver ? oldEnabled : false;
    if (oldEnabled) {
      prefs.setBool(useOilScreensaverKey, useOilScreensaver);
    }
    prefs.remove('use_screensaver');
  } else {
    useOilScreensaver =
        prefs.getBool(useOilScreensaverKey) ?? defaultScreensaver;
  }

  var appFont = prefs.getString(appFontKey) ?? DefaultSettings.appFont;
  if (prefs.containsKey('use_handwriting_font')) {
    final oldHandwriting = prefs.getBool('use_handwriting_font') ?? false;
    appFont = oldHandwriting ? 'caveat' : 'default';
    if (oldHandwriting) {
      prefs.setString(appFontKey, 'caveat');
    }
    prefs.remove('use_handwriting_font');
  }

  return LegacyCoreMigrationResult(
    useOilScreensaver: useOilScreensaver,
    appFont: appFont,
  );
}
