part of 'settings_provider.dart';

const String _audioEngineModeKey = 'audio_engine_mode';
const String _webPrefetchSecondsKey = 'web_prefetch_seconds';
const String _trackTransitionModeKey = 'track_transition_mode';
const String _crossfadeDurationSecondsKey = 'crossfade_duration_seconds';
const String _hybridHandoffModeKey = 'hybrid_handoff_mode';
const String _hybridBackgroundModeKey = 'hybrid_background_mode';
const String _allowHiddenWebAudioKey = 'allow_hidden_web_audio';
const String _usePlayPauseFadeKey = 'use_play_pause_fade';
const String _handoffCrossfadeMsKey = 'handoff_crossfade_ms';
const String _hiddenSessionPresetKey = 'hidden_session_preset';
const String _webEngineProfileInitKey = 'web_engine_profile_init_v1';
const String _webEngineProfileChoiceKey = 'web_engine_profile_choice';
const String _pauseOnOutputDisconnectKey = 'pause_on_output_disconnect';

mixin _SettingsProviderWebFields {
  late AudioEngineMode _audioEngineMode;
  late int _webPrefetchSeconds;
  late String _trackTransitionMode;
  late double _crossfadeDurationSeconds;
  late HybridHandoffMode _hybridHandoffMode;
  late HybridBackgroundMode _hybridBackgroundMode;
  late bool _allowHiddenWebAudio;
  late bool _usePlayPauseFade;
  late int _handoffCrossfadeMs;
  late HiddenSessionPreset _hiddenSessionPreset;
  late WebEngineProfile _webEngineProfile;
  late bool _pauseOnOutputDisconnect;
}

mixin _SettingsProviderWebExtension
    on ChangeNotifier, _SettingsProviderWebFields {
  SharedPreferences get _prefs;
  Future<void> _updatePreference(String key, bool value);

  AudioEngineMode get audioEngineMode => _audioEngineMode;

  void setAudioEngineMode(AudioEngineMode mode) {
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
  bool get pauseOnOutputDisconnect => _pauseOnOutputDisconnect;

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
    _hybridHandoffMode = mode;
    _prefs.setString(_hybridHandoffModeKey, mode.name);
    notifyListeners();
  }

  void setAllowHiddenWebAudio(bool value) {
    _allowHiddenWebAudio = value;
    _prefs.setBool(_allowHiddenWebAudioKey, value);
    notifyListeners();
  }

  void togglePlayPauseFade() {
    _usePlayPauseFade = !_usePlayPauseFade;
    _updatePreference(_usePlayPauseFadeKey, _usePlayPauseFade);
  }

  void togglePauseOnOutputDisconnect() {
    _pauseOnOutputDisconnect = !_pauseOnOutputDisconnect;
    _updatePreference(_pauseOnOutputDisconnectKey, _pauseOnOutputDisconnect);
  }

  void setHandoffCrossfadeMs(int ms) {
    _handoffCrossfadeMs = ms.clamp(0, 200);
    _prefs.setInt(_handoffCrossfadeMsKey, _handoffCrossfadeMs);
    notifyListeners();
  }

  void setHybridBackgroundMode(HybridBackgroundMode mode) {
    _hybridBackgroundMode = mode;
    _prefs.setString(_hybridBackgroundModeKey, mode.name);
    notifyListeners();
  }

  void setHiddenSessionPreset(HiddenSessionPreset preset) {
    _hiddenSessionPreset = preset;

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
    _webPrefetchSeconds = seconds;
    _prefs.setInt(_webPrefetchSecondsKey, seconds);
    notifyListeners();
  }
}
