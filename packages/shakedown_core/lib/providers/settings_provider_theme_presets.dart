part of 'settings_provider.dart';

mixin _SettingsProviderThemePresetsExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderPlatformDefaultsExtension {
  SharedPreferences get _prefs;
  @override
  bool get isTv;
  void setHiddenSessionPreset(
    HiddenSessionPreset preset, {
    bool markPowerProfileCustom = true,
  });
  void setGlowMode(int mode);
  void setHighlightPlayingWithRgb(bool value);

  void resetAndroidFirstTimeSettings() {
    _appFont = 'rock_salt';
    _prefs.setString(_appFontKey, 'rock_salt');

    final lowPower = kIsWeb && isLikelyLowPowerWebDevice();
    if (lowPower) {
      _performanceMode = true;
      _prefs.setBool(_performanceModeKey, true);
    } else {
      _performanceMode = false;
      _prefs.setBool(_performanceModeKey, false);
      setGlowMode(25);
      setHighlightPlayingWithRgb(true);
    }

    _resetWebPlaybackSettings();
    notifyListeners();
  }

  void resetFruitFirstTimeSettings() {
    _fruitDenseList = false;
    _prefs.setBool(_fruitDenseListKey, false);
    _fruitFloatingSpheres = false;
    _prefs.setBool(_fruitFloatingSpheresKey, false);
    _simpleRandomIcon = false;
    _prefs.setBool(_simpleRandomIconKey, false);
    _performanceMode = true;
    _prefs.setBool(_performanceModeKey, true);
    _oilBannerGlow = false;
    _prefs.setBool(_oilBannerGlowKey, false);
    setGlowMode(0);
    setHighlightPlayingWithRgb(false);

    if (kIsWeb && isLikelyLowPowerWebDevice()) {
      _fruitEnableLiquidGlass = false;
      _prefs.setBool(_fruitEnableLiquidGlassKey, false);
    }

    _resetWebPlaybackSettings();
    notifyListeners();
  }

  void _resetWebPlaybackSettings() {
    if (!kIsWeb) return;

    final profile = detectWebRuntimeProfile();
    final isSafari = isSafariWeb();

    switch (profile) {
      case WebRuntimeProfile.low:
        setHiddenSessionPreset(
          HiddenSessionPreset.stability,
          markPowerProfileCustom: false,
        );
        break;
      case WebRuntimeProfile.pwa:
        setHiddenSessionPreset(
          HiddenSessionPreset.balanced,
          markPowerProfileCustom: false,
        );
        break;
      case WebRuntimeProfile.web:
        setHiddenSessionPreset(
          isSafari
              ? HiddenSessionPreset.stability
              : HiddenSessionPreset.balanced,
          markPowerProfileCustom: false,
        );
        break;
      case WebRuntimeProfile.desk:
        setHiddenSessionPreset(
          isSafari
              ? HiddenSessionPreset.balanced
              : HiddenSessionPreset.maxGapless,
          markPowerProfileCustom: false,
        );
        break;
    }
  }
}
