part of 'settings_provider.dart';

mixin _SettingsProviderUiScaleChannelExtension
    on ChangeNotifier, _SettingsProviderCoreFields {
  SharedPreferences get _prefs;

  void _setupUiScaleChannel() {
    _uiScaleChannel.setMethodCallHandler((call) async {
      if (call.method != 'setUiScale') return;

      final enabled = call.arguments as bool;
      if (enabled == _uiScale) return;

      await _setUiScale(enabled);
      logger.i('SettingsProvider: UI Scale set to $enabled via ADB');
    });
  }

  Future<void> _setUiScale(bool enabled) async {
    _uiScale = enabled;
    _abbreviateDayOfWeek = enabled;
    _abbreviateMonth = enabled;

    await _prefs.setBool(_uiScaleKey, enabled);
    await _prefs.setBool(_abbreviateDayOfWeekKey, _abbreviateDayOfWeek);
    await _prefs.setBool(_abbreviateMonthKey, _abbreviateMonth);
    notifyListeners();
  }
}
