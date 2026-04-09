import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/providers/settings_init/settings_defaults.dart';

bool loadPreventSleepPreference(
  SharedPreferences prefs, {
  required String preventSleepKey,
  required bool isTv,
  required bool isWeb,
}) {
  if (prefs.containsKey('prevent_screensaver') &&
      !prefs.containsKey(preventSleepKey)) {
    final migrated =
        prefs.getBool('prevent_screensaver') ?? DefaultSettings.preventSleep;
    prefs.setBool(preventSleepKey, migrated);
    prefs.remove('prevent_screensaver');
    return migrated;
  }

  return prefs.getBool(preventSleepKey) ??
      resolveBoolDefault(
        webVal: DefaultSettings.preventSleep,
        tvVal: TvDefaults.preventSleep,
        phoneVal: PhoneDefaults.preventSleep,
        isTv: isTv,
        isWeb: isWeb,
      );
}
