part of 'settings_provider.dart';

mixin _SettingsProviderWebExtension
    on
        ChangeNotifier,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields {
  SharedPreferences get _prefs;
  Future<void> _updatePreference(String key, bool value);

  AudioEngineMode get audioEngineMode => _audioEngineMode;

  void setAudioEngineMode(AudioEngineMode mode) {
    _markWebPlaybackPowerProfileCustom();
    _audioEngineMode = mode;
    _prefs.setString(_audioEngineModeKey, mode.name);
    notifyListeners();
  }

  bool get webGaplessEngine => _audioEngineMode != AudioEngineMode.standard;

  int get webPrefetchSeconds => _webPrefetchSeconds;
  String get trackTransitionMode => _trackTransitionMode;
  double get crossfadeDurationSeconds => _crossfadeDurationSeconds;
  HybridHandoffMode get hybridHandoffMode => _hybridHandoffMode;
  HybridBackgroundMode get hybridBackgroundMode => _hybridBackgroundMode;
  bool get allowHiddenWebAudio => _allowHiddenWebAudio;
  bool get usePlayPauseFade => _usePlayPauseFade;
  int get handoffCrossfadeMs => _handoffCrossfadeMs;
  HiddenSessionPreset get hiddenSessionPreset => _hiddenSessionPreset;
  WebEngineProfile get webEngineProfile => _webEngineProfile;
  WebPlaybackPowerProfile get webPlaybackPowerProfile =>
      _webPlaybackPowerProfile;
  ResolvedWebPlaybackPowerSource get resolvedWebPlaybackPowerSource =>
      _resolvedWebPlaybackPowerSource;
  bool? get detectedWebCharging => _detectedWebCharging;

  void setTrackTransitionMode(String mode) {
    final normalized = mode == 'gap' ? 'gap' : 'gapless';
    _trackTransitionMode = normalized;
    _prefs.setString(_trackTransitionModeKey, normalized);
    notifyListeners();
  }

  void setCrossfadeDurationSeconds(double seconds) {
    _crossfadeDurationSeconds = seconds;
    _prefs.setDouble(_crossfadeDurationSecondsKey, seconds);
    notifyListeners();
  }

  void setHybridHandoffMode(HybridHandoffMode mode) {
    _markWebPlaybackPowerProfileCustom();
    _hybridHandoffMode = mode;
    _prefs.setString(_hybridHandoffModeKey, mode.name);
    notifyListeners();
  }

  void setAllowHiddenWebAudio(bool value) {
    _markWebPlaybackPowerProfileCustom();
    _allowHiddenWebAudio = value;
    _prefs.setBool(_allowHiddenWebAudioKey, value);
    notifyListeners();
  }

  void togglePlayPauseFade() {
    _usePlayPauseFade = !_usePlayPauseFade;
    _updatePreference(_usePlayPauseFadeKey, _usePlayPauseFade);
  }

  void setHandoffCrossfadeMs(int ms) {
    _handoffCrossfadeMs = ms.clamp(0, 200);
    _prefs.setInt(_handoffCrossfadeMsKey, _handoffCrossfadeMs);
    notifyListeners();
  }

  void setHybridBackgroundMode(HybridBackgroundMode mode) {
    _markWebPlaybackPowerProfileCustom();
    _hybridBackgroundMode = mode;
    _prefs.setString(_hybridBackgroundModeKey, mode.name);
    notifyListeners();
  }

  void setHiddenSessionPreset(
    HiddenSessionPreset preset, {
    bool markPowerProfileCustom = true,
  }) {
    _hiddenSessionPreset = preset;
    if (markPowerProfileCustom) {
      _webPlaybackPowerProfile = WebPlaybackPowerProfile.custom;
      _resolvedWebPlaybackPowerSource = ResolvedWebPlaybackPowerSource.custom;
    }

    switch (preset) {
      case HiddenSessionPreset.stability:
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.none;
        _hybridBackgroundMode = HybridBackgroundMode.html5;
        _allowHiddenWebAudio = false;
        break;
      case HiddenSessionPreset.balanced:
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.heartbeat;
        _allowHiddenWebAudio = false;
        break;
      case HiddenSessionPreset.maxGapless:
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.none;
        _allowHiddenWebAudio = true;
        break;
    }

    _prefs.setString(_hiddenSessionPresetKey, _hiddenSessionPreset.name);
    if (markPowerProfileCustom) {
      _prefs.setString(
        _webPlaybackPowerProfileKey,
        _webPlaybackPowerProfile.name,
      );
    }
    _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
    _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
    _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
    notifyListeners();
  }

  void setWebEngineProfile(WebEngineProfile profile) {
    if (!kIsWeb) return;
    _webEngineProfile = profile;
    _applyWebEngineProfile(profile, persistPrefs: true);
    _prefs.setBool(_webEngineProfileInitKey, true);
    _prefs.setString(_webEngineProfileChoiceKey, profile.name);
    notifyListeners();
  }

  void _applyWebEngineProfile(
    WebEngineProfile profile, {
    required bool persistPrefs,
  }) {
    switch (profile) {
      case WebEngineProfile.modern:
        _hiddenSessionPreset = HiddenSessionPreset.balanced;
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.heartbeat;
        _allowHiddenWebAudio = false;
        break;
      case WebEngineProfile.legacy:
        _hiddenSessionPreset = HiddenSessionPreset.stability;
        _audioEngineMode = AudioEngineMode.html5;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.video;
        _allowHiddenWebAudio = false;
        break;
    }

    if (!persistPrefs) return;

    _prefs.setString(_hiddenSessionPresetKey, _hiddenSessionPreset.name);
    _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
    _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
    _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
  }

  void toggleWebGaplessEngine() {
    setAudioEngineMode(
      webGaplessEngine ? AudioEngineMode.standard : AudioEngineMode.auto,
    );
  }

  void setWebPrefetchSeconds(int seconds) {
    _markWebPlaybackPowerProfileCustom();
    _webPrefetchSeconds = seconds;
    _prefs.setInt(_webPrefetchSecondsKey, seconds);
    notifyListeners();
  }

  void setWebPlaybackPowerProfile(WebPlaybackPowerProfile profile) {
    _webPlaybackPowerProfile = profile;
    _prefs.setString(_webPlaybackPowerProfileKey, profile.name);
    _applyWebPlaybackPowerPolicy(persistPrefs: true);
    notifyListeners();
  }

  void _markWebPlaybackPowerProfileCustom() {
    if (_applyingWebPowerPolicy ||
        _webPlaybackPowerProfile == WebPlaybackPowerProfile.custom) {
      return;
    }

    _webPlaybackPowerProfile = WebPlaybackPowerProfile.custom;
    _resolvedWebPlaybackPowerSource = ResolvedWebPlaybackPowerSource.custom;
    _prefs.setString(
      _webPlaybackPowerProfileKey,
      WebPlaybackPowerProfile.custom.name,
    );
  }

  void _applyWebPlaybackPowerPolicy({required bool persistPrefs}) {
    final config = resolveWebPlaybackPowerPolicy(
      profile: _webPlaybackPowerProfile,
      detectedCharging: _detectedWebCharging,
    );
    _resolvedWebPlaybackPowerSource = config.resolvedSource;

    if (!config.applyEngineSettings) {
      return;
    }

    _applyingWebPowerPolicy = true;
    try {
      final audioEngineMode = config.audioEngineMode!;
      final handoffMode = config.handoffMode!;
      final backgroundMode = config.backgroundMode!;
      final allowHiddenWebAudio = config.allowHiddenWebAudio!;
      final webPrefetchSeconds = config.webPrefetchSeconds!;
      final preventSleep = config.preventSleep!;

      _audioEngineMode = audioEngineMode;
      _hybridHandoffMode = handoffMode;
      _hybridBackgroundMode = backgroundMode;
      _allowHiddenWebAudio = allowHiddenWebAudio;
      _webPrefetchSeconds = webPrefetchSeconds;
      _preventSleep = preventSleep;

      if (!persistPrefs) {
        return;
      }

      _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
      _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
      _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
      _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
      _prefs.setInt(_webPrefetchSecondsKey, _webPrefetchSeconds);
      _prefs.setBool(_preventSleepKey, _preventSleep);
    } finally {
      _applyingWebPowerPolicy = false;
    }
  }
}
