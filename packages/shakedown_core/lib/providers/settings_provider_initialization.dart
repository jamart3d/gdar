part of 'settings_provider.dart';

mixin _SettingsProviderInitializationExtension
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
        _SettingsProviderPlatformDefaultsExtension,
        _SettingsProviderThemePresetsExtension,
        _SettingsProviderCoreLoaderExtension,
        _SettingsProviderScreensaverLoaderExtension,
        _SettingsProviderSourceFilterLoaderExtension {
  @override
  SharedPreferences get _prefs;
  @override
  bool get isTv;
  @override
  void setHiddenSessionPreset(
    HiddenSessionPreset preset, {
    bool markPowerProfileCustom = true,
  });
  @override
  void setGlowMode(int mode);
  @override
  void setHighlightPlayingWithRgb(bool value);
  @override
  void _applyWebPlaybackPowerPolicy({required bool persistPrefs});
  @override
  void _markWebPlaybackPowerProfileCustom();
}
