import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/providers/settings_init/settings_defaults.dart';

int loadOilPerformanceLevelPreference(
  SharedPreferences prefs, {
  required String oilPerformanceLevelKey,
  required bool isTv,
  required bool isWeb,
}) {
  if (!prefs.containsKey(oilPerformanceLevelKey) &&
      !prefs.containsKey('oil_performance_mode')) {
    return resolveIntDefault(
      webVal: DefaultSettings.oilPerformanceLevel,
      tvVal: TvDefaults.oilPerformanceLevel,
      phoneVal: DefaultSettings.oilPerformanceLevel,
      isTv: isTv,
      isWeb: isWeb,
    );
  }

  return prefs.getInt(oilPerformanceLevelKey) ??
      (prefs.getBool('oil_performance_mode') == true ? 2 : 0);
}

String loadOilBannerFontPreference(
  SharedPreferences prefs, {
  required String oilBannerFontKey,
}) {
  final storedFont =
      prefs.getString(oilBannerFontKey) ?? DefaultSettings.oilBannerFont;
  if (storedFont != 'rock_salt') {
    return storedFont;
  }

  prefs.setString(oilBannerFontKey, 'RockSalt');
  return 'RockSalt';
}
