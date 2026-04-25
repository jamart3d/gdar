part of 'settings_provider.dart';

mixin _SettingsProviderWebLoaderExtension
    on
        ChangeNotifier,
        _SettingsProviderWebFields,
        _SettingsProviderPlatformDefaultsExtension,
        _SettingsProviderThemePresetsExtension {
  @override
  SharedPreferences get _prefs;
  @override
  bool get isTv;
  void _applyWebPlaybackPowerPolicy({required bool persistPrefs});

  void _loadWebPlaybackPreferences() {
    _audioEngineMode = _loadAudioEngineModePreference();
    _webEngineProfile = WebEngineProfile.fromString(
      _prefs.getString(_webEngineProfileChoiceKey),
    );
    _applyAdaptiveWebEngineProfileIfNeeded();

    _webPrefetchSeconds = _audioEngineMode == AudioEngineMode.webAudio
        ? -1
        : DefaultSettings.webPrefetchSeconds;
    if (_prefs.getInt(_webPrefetchSecondsKey) != _webPrefetchSeconds) {
      _prefs.setInt(_webPrefetchSecondsKey, _webPrefetchSeconds);
    }

    _trackTransitionMode =
        _prefs.getString(_trackTransitionModeKey) ??
        DefaultSettings.trackTransitionMode;
    if (_trackTransitionMode == 'crossfade') {
      _trackTransitionMode = 'gapless';
      _prefs.setString(_trackTransitionModeKey, _trackTransitionMode);
    }

    _crossfadeDurationSeconds =
        _prefs.getDouble(_crossfadeDurationSecondsKey) ??
        DefaultSettings.crossfadeDurationSeconds;
    _hybridHandoffMode = HybridHandoffMode.fromString(
      _prefs.getString(_hybridHandoffModeKey) ?? 'buffered',
    );
    _hybridBackgroundMode = HybridBackgroundMode.fromString(
      _prefs.getString(_hybridBackgroundModeKey) ?? 'heartbeat',
    );
    _hiddenSessionPreset = HiddenSessionPreset.fromString(
      _prefs.getString(_hiddenSessionPresetKey) ?? 'balanced',
    );
    _allowHiddenWebAudio = _prefs.getBool(_allowHiddenWebAudioKey) ?? false;
    _usePlayPauseFade = _prefs.getBool(_usePlayPauseFadeKey) ?? true;
    _handoffCrossfadeMs =
        _prefs.getInt(_handoffCrossfadeMsKey) ??
        DefaultSettings.handoffCrossfadeMs;
    _webPlaybackPowerProfile = WebPlaybackPowerProfile.fromString(
      _prefs.getString(_webPlaybackPowerProfileKey),
    );
    _resolvedWebPlaybackPowerSource = resolveWebPlaybackPowerPolicy(
      profile: _webPlaybackPowerProfile,
      detectedCharging: _detectedWebCharging,
    ).resolvedSource;
    if (kIsWeb) {
      _applyWebPlaybackPowerPolicy(persistPrefs: true);
      _startWebPowerStateListener();
    }
  }

  AudioEngineMode _loadAudioEngineModePreference() {
    if (_prefs.containsKey('web_gapless_engine')) {
      final oldEnabled = _prefs.getBool('web_gapless_engine') ?? true;
      final migrated = oldEnabled
          ? AudioEngineMode.auto
          : AudioEngineMode.standard;
      _prefs.remove('web_gapless_engine');
      _prefs.setString(_audioEngineModeKey, migrated.name);
      return migrated;
    }

    return AudioEngineMode.fromString(
      _prefs.getString(_audioEngineModeKey) ??
          _dStr(
            WebDefaults.audioEngineMode,
            PhoneDefaults.audioEngineMode,
            PhoneDefaults.audioEngineMode,
          ),
    );
  }

  void _applyAdaptiveWebEngineProfileIfNeeded() {
    final hasAdaptiveProfileInit =
        _prefs.getBool(_webEngineProfileInitKey) ?? false;
    final hasExplicitEngineOverride =
        _prefs.containsKey(_audioEngineModeKey) &&
        _audioEngineMode != AudioEngineMode.auto;

    if (!kIsWeb || hasAdaptiveProfileInit || hasExplicitEngineOverride) {
      return;
    }

    // Delegate to the hardware-aware decision tree for first-run defaults
    _resetWebPlaybackSettings();
    _webEngineProfile = isLikelyLowPowerWebDevice()
        ? WebEngineProfile.legacy
        : WebEngineProfile.modern;

    _prefs.setBool(_webEngineProfileInitKey, true);
    _prefs.setString(_webEngineProfileChoiceKey, _webEngineProfile.name);
    logger.i(
      'SettingsProvider: Adaptive web engine profile applied (Decision Tree Logic).',
    );
  }

  void _startWebPowerStateListener() {
    if (!kIsWeb || _webChargingSubscription != null) {
      return;
    }

    getInitialWebChargingState().then((charging) {
      _handleWebChargingState(charging);
    });

    _webChargingSubscription = onWebChargingStateChanged.listen(
      _handleWebChargingState,
    );
  }

  void _handleWebChargingState(bool? charging) {
    if (_webPowerStateDisposed) {
      return;
    }

    if (_detectedWebCharging == charging) {
      return;
    }

    _detectedWebCharging = charging;
    if (_webPlaybackPowerProfile == WebPlaybackPowerProfile.auto) {
      _applyWebPlaybackPowerPolicy(persistPrefs: true);
      notifyListeners();
    }
  }
}
