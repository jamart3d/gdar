part of 'settings_provider.dart';

mixin _SettingsProviderBootstrapExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields,
        _SettingsProviderCoreExtension,
        _SettingsProviderWebExtension,
        _SettingsProviderScreensaverExtension,
        _SettingsProviderSourceFiltersExtension,
        _SettingsProviderInitializationExtension,
        _SettingsProviderThemePresetsExtension {
  SharedPreferences get _prefs;
  bool get isTv;

  void _init() {
    _initializeFirstRunState();
    _loadCorePreferences();
    _loadWebPlaybackPreferences();
    _loadScreensaverPreferences();
    _loadSourceFilterPreferences();
  }

  void _initializeFirstRunState() {
    final firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;
    _uiScale =
        _prefs.getBool(_uiScaleKey) ?? DefaultSettings.uiScaleDesktopDefault;

    if (firstRunCheckDone) return;

    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      final view = views.first;
      final physicalWidth = view.physicalSize.width;
      if (isTv) {
        _uiScale = false;
        _prefs.setBool(_uiScaleKey, false);
      } else if (physicalWidth <= 720) {
        _uiScale = DefaultSettings.uiScaleMobileDefault;
        _prefs.setBool(_uiScaleKey, DefaultSettings.uiScaleMobileDefault);
      }
    }

    _isFirstRun = true;
    _prefs.setBool('first_run_check_done', true);
  }
}
