import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/song_structure_hints.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/ui/navigation/route_names.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/visualizer/audio_reactor_factory.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/song_structure_hint_service.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screensaver screen displaying the Steal Your Face visualizer.
/// Note: This screensaver and its audio reactivity are explicitly for the TV UI.
class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({
    super.key,
    this.songHintCatalogOverride,
    this.allowPermissionPrompts = true,
  });

  final SongStructureHintCatalog? songHintCatalogOverride;
  final bool allowPermissionPrompts;

  static Route<void> route({
    SongStructureHintCatalog? songHintCatalogOverride,
    bool allowPermissionPrompts = true,
  }) {
    return PageRouteBuilder(
      settings: const RouteSettings(name: ShakedownRouteNames.screensaver),
      opaque: false,
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          ScreensaverScreen(
            songHintCatalogOverride: songHintCatalogOverride,
            allowPermissionPrompts: allowPermissionPrompts,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(route());
  }

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  AudioReactor? _audioReactor;
  int? _debugAudioSessionId;
  bool _isInitializingAudioReactor = false;
  bool _isPermissionFlowActive = false;
  bool _isPermissionFlowCooldown = false;
  Timer? _permissionFlowCooldownTimer;
  Timer? _sessionRetryTimer;
  int _sessionRetryCount = 0;
  static const int _maxSessionRetries = 10;
  WakelockService? _wakelockService;
  bool _isStereoCapturePending = false;
  bool _isStereoCaptureActive = false;
  bool _hasAttemptedStereoCapture = false;
  final SongStructureHintService _songHintService =
      const SongStructureHintService();
  SongStructureHintCatalog? _songHintCatalog;

  double? _lastPushedPeakDecay;
  double? _lastPushedBassBoost;
  double? _lastPushedReactivityStrength;
  String? _lastPushedBeatDetectorMode;
  String? _lastPushedAutocorrBeatVariant;
  String? _lastPushedAutocorrLogoVariant;
  double? _lastPushedBeatSensitivity;
  bool? _lastPushedAutocorrSecondPass;
  bool? _lastPushedAutocorrSecondPassHq;

  @override
  void initState() {
    super.initState();
    _songHintCatalog = widget.songHintCatalogOverride;
    if (_songHintCatalog == null) {
      _loadSongHintCatalog();
    }
    _initAudioReactor();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wakelockService == null) {
      _wakelockService = Provider.of<WakelockService>(context, listen: false);
      _wakelockService?.enable();
    }
  }

  @override
  void didUpdateWidget(ScreensaverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _pushAudioConfig(SettingsProvider settings) {
    if (_audioReactor is! VisualizerAudioReactor) return;
    final reactor = _audioReactor as VisualizerAudioReactor;

    final peakDecay = settings.oilAudioPeakDecay;
    final bassBoost = settings.oilAudioBassBoost;
    final reactivityStrength = settings.oilAudioReactivityStrength;
    final beatDetectorMode = settings.oilBeatDetectorMode;
    final autocorrBeatVariant = settings.oilAutocorrBeatVariant;
    final autocorrLogoVariant = settings.oilAutocorrLogoVariant;
    final beatSensitivity = settings.oilBeatSensitivity;
    final autocorrSecondPass = settings.beatAutocorrSecondPass;
    final autocorrSecondPassHq = settings.beatAutocorrSecondPassHq;
    final unchanged =
        _lastPushedPeakDecay == peakDecay &&
        _lastPushedBassBoost == bassBoost &&
        _lastPushedReactivityStrength == reactivityStrength &&
        _lastPushedBeatDetectorMode == beatDetectorMode &&
        _lastPushedAutocorrBeatVariant == autocorrBeatVariant &&
        _lastPushedAutocorrLogoVariant == autocorrLogoVariant &&
        _lastPushedBeatSensitivity == beatSensitivity &&
        _lastPushedAutocorrSecondPass == autocorrSecondPass &&
        _lastPushedAutocorrSecondPassHq == autocorrSecondPassHq;
    if (unchanged) return;

    reactor.updateConfig(
      peakDecay: peakDecay,
      bassBoost: bassBoost,
      reactivityStrength: reactivityStrength,
      beatDetectorMode: beatDetectorMode,
      autocorrBeatVariant: autocorrBeatVariant,
      autocorrLogoVariant: autocorrLogoVariant,
      beatSensitivity: beatSensitivity,
      autocorrSecondPass: autocorrSecondPass,
      autocorrSecondPassHq: autocorrSecondPassHq,
    );

    _lastPushedPeakDecay = peakDecay;
    _lastPushedBassBoost = bassBoost;
    _lastPushedReactivityStrength = reactivityStrength;
    _lastPushedBeatDetectorMode = beatDetectorMode;
    _lastPushedAutocorrBeatVariant = autocorrBeatVariant;
    _lastPushedAutocorrLogoVariant = autocorrLogoVariant;
    _lastPushedBeatSensitivity = beatSensitivity;
    _lastPushedAutocorrSecondPass = autocorrSecondPass;
    _lastPushedAutocorrSecondPassHq = autocorrSecondPassHq;
  }

  bool _wantsStereoCapture(SettingsProvider settings) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (!settings.oilEnableAudioReactivity) {
      return false;
    }
    if (_audioReactor is! VisualizerAudioReactor) {
      return false;
    }
    // Request MediaProjection only when the user explicitly selects the
    // enhanced PCM detector mode. All other modes stay on the FFT path and
    // avoid the system share-screen permission prompt.
    return settings.oilBeatDetectorMode == 'pcm';
  }

  Future<void> _syncStereoCapture(SettingsProvider settings) async {
    final wantsStereoCapture = _wantsStereoCapture(settings);

    logger.i(
      'Screensaver: syncStereoCapture '
      '(wants=$wantsStereoCapture, '
      'allowPermissionPrompts=${widget.allowPermissionPrompts}, '
      'audioReactivity=${settings.oilEnableAudioReactivity}, '
      'beatDetectorMode=${settings.oilBeatDetectorMode}, '
      'audioGraphMode=${settings.oilAudioGraphMode}, '
      'isStereoCaptureActive=$_isStereoCaptureActive, '
      'isStereoCapturePending=$_isStereoCapturePending, '
      'hasAttemptedStereoCapture=$_hasAttemptedStereoCapture)',
    );

    if (!wantsStereoCapture) {
      logger.i('Screensaver: stereo capture not wanted, stopping/resetting');
      await _stopStereoCapture(resetAttempt: true);
      return;
    }

    if (_isStereoCaptureActive ||
        _isStereoCapturePending ||
        _hasAttemptedStereoCapture) {
      logger.i(
        'Screensaver: stereo capture request skipped '
        '(active=$_isStereoCaptureActive, '
        'pending=$_isStereoCapturePending, '
        'attempted=$_hasAttemptedStereoCapture)',
      );
      return;
    }

    if (!widget.allowPermissionPrompts) {
      logger.i(
        'Screensaver: Skipping enhanced capture request during '
        'non-interactive launch.',
      );
      return;
    }

    _isStereoCapturePending = true;
    _hasAttemptedStereoCapture = true;
    logger.i('Screensaver: requesting stereo capture permission');
    final started = await _runPermissionFlow(
      () => VisualizerAudioReactor.requestStereoCapture().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.w('Screensaver: stereo capture request timed out');
          return false;
        },
      ),
    );
    _isStereoCapturePending = false;
    logger.i(
      'Screensaver: stereo capture request completed (started=$started)',
    );

    // Allow retry on failure so the user can try again without switching modes.
    if (!started) {
      _hasAttemptedStereoCapture = false;
    }

    if (!mounted) {
      if (started) {
        await VisualizerAudioReactor.stopStereoCapture();
      }
      return;
    }

    _isStereoCaptureActive = started;
  }

  Future<void> _stopStereoCapture({bool resetAttempt = false}) async {
    if (!_isStereoCaptureActive && !_isStereoCapturePending) {
      if (resetAttempt) {
        _hasAttemptedStereoCapture = false;
      }
      return;
    }
    _isStereoCapturePending = false;
    _isStereoCaptureActive = false;
    if (resetAttempt) {
      _hasAttemptedStereoCapture = false;
    }
    await VisualizerAudioReactor.stopStereoCapture();
  }

  bool _shouldDeferMicrophonePermission(
    SettingsProvider settings,
    DeviceService deviceService,
  ) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return deviceService.isTv && settings.oilBeatDetectorMode == 'pcm';
  }

  Future<PermissionStatus?> _getMicrophonePermissionStatus() async {
    try {
      return await Permission.microphone.status;
    } catch (error) {
      debugPrint(
        'Screensaver: Failed to read microphone permission status: $error',
      );
      return null;
    }
  }

  Future<PermissionStatus?> _requestMicrophonePermission() async {
    try {
      return await _runPermissionFlow(Permission.microphone.request);
    } catch (error) {
      debugPrint(
        'Screensaver: Failed to request microphone permission: $error',
      );
      return null;
    }
  }

  Future<AudioReactor?> _createStartedAudioReactor({
    required int? audioSessionId,
    required bool isTv,
  }) async {
    logger.i(
      'Screensaver: creating audio reactor '
      '(audioSessionId=$audioSessionId, isTv=$isTv)',
    );
    final reactor = await AudioReactorFactory.create(
      audioSessionId: audioSessionId,
      isTv: isTv,
    );
    if (reactor == null) {
      logger.w('Screensaver: audio reactor factory returned null');
      return null;
    }
    logger.i('Screensaver: audio reactor created (${reactor.runtimeType})');
    final started = await reactor.start();
    if (!started) {
      logger.w('Screensaver: audio reactor failed to start');
      reactor.dispose();
      return null;
    }
    logger.i('Screensaver: audio reactor started (${reactor.runtimeType})');
    return reactor;
  }

  Future<void> _loadSongHintCatalog() async {
    try {
      final catalog = await _songHintService.loadCatalog();
      if (!mounted) return;
      setState(() => _songHintCatalog = catalog);
    } catch (error) {
      debugPrint('Screensaver: Failed to load song structure hints: $error');
    }
  }

  SongStructureHintEntry? _bestSongHintForTitle(String? title) {
    if (title == null || title.trim().isEmpty) return null;
    final catalog = _songHintCatalog;
    if (catalog == null) return null;

    final normalizedTitle = SongStructureHintEntry.normalizeLookupKey(title);
    final matches = catalog.lookup(title);
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final aTitleExact =
          SongStructureHintEntry.normalizeLookupKey(a.title) == normalizedTitle;
      final bTitleExact =
          SongStructureHintEntry.normalizeLookupKey(b.title) == normalizedTitle;
      if (aTitleExact != bTitleExact) {
        return aTitleExact ? -1 : 1;
      }

      final aCanonicalExact =
          SongStructureHintEntry.normalizeLookupKey(a.canonicalTitle) ==
          normalizedTitle;
      final bCanonicalExact =
          SongStructureHintEntry.normalizeLookupKey(b.canonicalTitle) ==
          normalizedTitle;
      if (aCanonicalExact != bCanonicalExact) {
        return aCanonicalExact ? -1 : 1;
      }

      final confidenceCompare = b.confidence.compareTo(a.confidence);
      if (confidenceCompare != 0) return confidenceCompare;

      if (a.variant == b.variant) return 0;
      if (a.variant == 'main') return -1;
      if (b.variant == 'main') return 1;
      return a.variant.compareTo(b.variant);
    });

    return matches.first;
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (_isPermissionFlowActive || _isPermissionFlowCooldown) {
      return false;
    }
    if (event is KeyDownEvent) {
      if (mounted) {
        Future.microtask(() {
          if (mounted) Navigator.of(context).pop();
        });
        return true;
      }
    }
    return false;
  }

  Future<void> _initAudioReactor({bool isRetry = false}) async {
    if (_isInitializingAudioReactor) return;
    if (_audioReactor != null && !isRetry) return;
    _isInitializingAudioReactor = true;

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final deviceService = Provider.of<DeviceService>(context, listen: false);

      // Web never has the real visualizer, and if reactivity is off skip entirely.
      if (kIsWeb || !settings.oilEnableAudioReactivity) return;

      PermissionStatus? microphoneStatus;
      final deferMicrophonePermission = _shouldDeferMicrophonePermission(
        settings,
        deviceService,
      );

      // Most Android visualizer paths still need RECORD_AUDIO. For explicit
      // TV Enhanced/PCM mode, try to start first and only prompt if we
      // actually need the runtime grant.
      if (defaultTargetPlatform == TargetPlatform.android) {
        microphoneStatus = await _getMicrophonePermissionStatus();
        if (microphoneStatus == null) {
          debugPrint(
            'Screensaver: Microphone permission state unavailable. '
            'Reactivity disabled for this session.',
          );
          return;
        }
        if (!deferMicrophonePermission && !microphoneStatus.isGranted) {
          if (!widget.allowPermissionPrompts) {
            debugPrint(
              'Screensaver: Skipping microphone permission request during '
              'non-interactive launch. Reactivity disabled for this session.',
            );
            return;
          }
          microphoneStatus = await _requestMicrophonePermission();
          if (microphoneStatus?.isGranted != true) {
            debugPrint(
              'Screensaver: Audio permission denied. Reactivity disabled.',
            );
            return;
          }
        } else if (deferMicrophonePermission &&
            !widget.allowPermissionPrompts &&
            !microphoneStatus.isGranted) {
          debugPrint(
            'Screensaver: Skipping deferred microphone permission request '
            'during non-interactive launch. Enhanced reactivity disabled '
            'for this session.',
          );
          return;
        }
      }

      // Get the app's audio session ID on Android so we tap the right output.
      if (!mounted) return;
      int? sessionId;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final audioProvider = Provider.of<AudioProvider>(
          context,
          listen: false,
        );
        sessionId = audioProvider.audioPlayer.androidAudioSessionId;
        _debugAudioSessionId = sessionId;
      }

      // If session ID is null or 0, schedule a retry — audio may not have
      // started yet. Retry up to 10 times with 2s intervals.
      if ((sessionId == null || sessionId == 0) &&
          _sessionRetryCount < _maxSessionRetries) {
        _sessionRetryCount++;
        debugPrint(
          'Screensaver: Session ID is $sessionId, scheduling retry '
          '$_sessionRetryCount/$_maxSessionRetries',
        );
        _sessionRetryTimer?.cancel();
        _sessionRetryTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _initAudioReactor(isRetry: true);
        });
        // Still initialize with 0 on first attempt so we get *something*
        if (_audioReactor != null) return;
      }

      // Dispose previous reactor if reinitializing with a better session ID.
      // Keep Enhanced capture running across session-id retries so Android
      // doesn't need to prompt again within the same app session.
      if (isRetry && _audioReactor != null) {
        _audioReactor?.dispose();
        _audioReactor = null;
        _clearPushedAudioConfig();
      }

      // Factory only returns a real reactor when isTv == true AND on Android.
      AudioReactor? reactor = await _createStartedAudioReactor(
        audioSessionId: sessionId,
        isTv: deviceService.isTv,
      );
      logger.i(
        'Screensaver: createStartedAudioReactor returned '
        '${reactor?.runtimeType ?? 'null'}',
      );

      if (reactor == null &&
          defaultTargetPlatform == TargetPlatform.android &&
          deferMicrophonePermission &&
          microphoneStatus != null &&
          !microphoneStatus.isGranted) {
        if (!widget.allowPermissionPrompts) {
          debugPrint(
            'Screensaver: Skipping deferred microphone permission request '
            'during non-interactive launch. Enhanced reactivity disabled '
            'for this session.',
          );
          return;
        }
        microphoneStatus = await _requestMicrophonePermission();
        if (microphoneStatus?.isGranted != true) {
          debugPrint(
            'Screensaver: Audio permission denied. Reactivity disabled.',
          );
          return;
        }
        reactor = await _createStartedAudioReactor(
          audioSessionId: sessionId,
          isTv: deviceService.isTv,
        );
      }

      if (!mounted) {
        reactor?.dispose();
        return;
      }

      if (reactor == null) {
        debugPrint(
          'Screensaver: Audio reactor unavailable. Reactivity disabled '
          'for this session.',
        );
        return;
      }

      logger.i('Screensaver: storing audio reactor (${reactor.runtimeType})');
      setState(() => _audioReactor = reactor);
      if (reactor is VisualizerAudioReactor) {
        logger.i('Screensaver: pushing audio config to VisualizerAudioReactor');
        _pushAudioConfig(settings);
        logger.i('Screensaver: calling _syncStereoCapture');
        await _syncStereoCapture(settings);
        logger.i('Screensaver: _syncStereoCapture completed');
      }
    } finally {
      _isInitializingAudioReactor = false;
    }
  }

  void _clearPushedAudioConfig() {
    _lastPushedPeakDecay = null;
    _lastPushedBassBoost = null;
    _lastPushedReactivityStrength = null;
    _lastPushedBeatDetectorMode = null;
    _lastPushedAutocorrBeatVariant = null;
    _lastPushedAutocorrLogoVariant = null;
    _lastPushedBeatSensitivity = null;
    _lastPushedAutocorrSecondPass = null;
    _lastPushedAutocorrSecondPassHq = null;
  }

  Future<T> _runPermissionFlow<T>(Future<T> Function() action) async {
    _isPermissionFlowActive = true;
    try {
      return await action();
    } finally {
      _isPermissionFlowActive = false;
      // Brief cooldown: the TV remote's OK press that confirmed the Android
      // permission dialog can fire a KeyDownEvent in Flutter right after the
      // native dialog dismisses. Without this guard, _handleGlobalKeyEvent
      // would immediately pop the screensaver.
      _isPermissionFlowCooldown = true;
      _permissionFlowCooldownTimer?.cancel();
      _permissionFlowCooldownTimer = Timer(
        const Duration(milliseconds: 600),
        () => _isPermissionFlowCooldown = false,
      );
    }
  }

  void _ensureAudioReactorState(SettingsProvider settings) {
    if (kIsWeb || !settings.oilEnableAudioReactivity) {
      if (_audioReactor != null) {
        unawaited(_stopStereoCapture(resetAttempt: true));
        _audioReactor?.dispose();
        _audioReactor = null;
        _clearPushedAudioConfig();
      }
      return;
    }

    if (_audioReactor == null && !_isInitializingAudioReactor) {
      _initAudioReactor();
    }
  }

  String _composeBannerText(SettingsProvider settings, AudioProvider audio) {
    if (!settings.oilShowInfoBanner) return '';
    return audio.currentTrack?.title ?? '';
  }

  String _composeVenue(SettingsProvider settings, AudioProvider audio) {
    if (!settings.oilShowInfoBanner) return '';
    return audio.currentShow?.venue ?? '';
  }

  String _composeDate(SettingsProvider settings, AudioProvider audio) {
    if (!settings.oilShowInfoBanner) return '';
    return audio.currentShow?.date ?? '';
  }

  @override
  void dispose() {
    _sessionRetryTimer?.cancel();
    _permissionFlowCooldownTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _wakelockService?.disable();
    // Preserve Enhanced capture across screensaver launches for the life of
    // the app session. It is still torn down when audio reactivity is
    // disabled, the detector switches away from Enhanced, or the activity
    // itself is destroyed.
    _audioReactor?.dispose();
    _audioReactor = null;
    _clearPushedAudioConfig();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final songHint = _bestSongHintForTitle(audioProvider.currentTrack?.title);

    _ensureAudioReactorState(settings);

    // Re-check session ID: if we initialized with null/0 but now have a real
    // one, reinitialize the reactor to tap the correct audio output.
    if (_audioReactor != null &&
        defaultTargetPlatform == TargetPlatform.android) {
      final freshId = audioProvider.audioPlayer.androidAudioSessionId;
      if (freshId != null &&
          freshId > 0 &&
          (_debugAudioSessionId == null || _debugAudioSessionId == 0)) {
        _debugAudioSessionId = freshId;
        _initAudioReactor(isRetry: true);
      }
    }

    if (_audioReactor != null) {
      _pushAudioConfig(settings);
      unawaited(_syncStereoCapture(settings));
    }

    final config = StealConfig(
      flowSpeed: settings.oilFlowSpeed,
      palette: settings.oilPalette,
      filmGrain: settings.oilFilmGrain,
      pulseIntensity: settings.oilPulseIntensity,
      heatDrift: settings.oilHeatDrift,
      enableAudioReactivity: settings.oilEnableAudioReactivity,
      performanceLevel: settings.oilPerformanceLevel,
      logoScale: settings.oilLogoScale,
      translationSmoothing: settings.oilTranslationSmoothing,
      blurAmount: settings.oilBlurAmount,
      flatColor: settings.oilFlatColor,
      bannerGlow: settings.oilBannerGlow,
      bannerFlicker: settings.oilBannerFlicker,
      showInfoBanner: settings.oilShowInfoBanner,
      bannerText: _composeBannerText(settings, audioProvider),
      venue: _composeVenue(settings, audioProvider),
      date: _composeDate(settings, audioProvider),
      trackHintId: songHint?.id ?? '',
      trackHintTitle: songHint?.canonicalTitle ?? '',
      trackHintVariant: songHint?.variant ?? '',
      trackHintSeedSource: songHint == null ? 'audio' : 'title',
      paletteCycle: settings.oilPaletteCycle,
      paletteTransitionSpeed: settings.oilPaletteTransitionSpeed,
      innerRingScale: settings.oilInnerRingScale,
      innerToMiddleGap: settings.oilInnerToMiddleGap,
      middleToOuterGap: settings.oilMiddleToOuterGap,
      orbitDrift: settings.oilOrbitDrift,
      bannerDisplayMode: settings.oilBannerDisplayMode,
      bannerFont: settings.oilBannerFont,
      logoTrailIntensity: settings.oilLogoTrailIntensity,
      logoTrailSlices: settings.oilLogoTrailSlices,
      logoTrailDynamic: settings.oilLogoTrailDynamic,
      logoTrailLength: settings.oilLogoTrailLength,
      flatTextProximity: settings.oilFlatTextProximity,
      flatTextPlacement: settings.oilFlatTextPlacement,
      audioGraphMode: settings.oilAudioGraphMode,
      beatDetectorMode: settings.oilBeatDetectorMode,
      autocorrBeatVariant: settings.oilAutocorrBeatVariant,
      autocorrLogoVariant: settings.oilAutocorrLogoVariant,
      ekgRadius: settings.oilEkgRadius,
      ekgReplication: settings.oilEkgReplication,
      ekgSpread: settings.oilEkgSpread,
      beatSensitivity: settings.oilBeatSensitivity,
      beatImpact: settings.oilBeatImpact,
      innerRingFontScale: settings.oilInnerRingFontScale,
      innerRingSpacingMultiplier: settings.oilInnerRingSpacingMultiplier,
      trackLetterSpacing: settings.oilTrackLetterSpacing,
      trackWordSpacing: settings.oilTrackWordSpacing,
      logoAntiAlias: settings.oilLogoAntiAlias,
      logoTrailScale: settings.oilLogoTrailScale,
      bannerResolution: settings.oilBannerResolution,
      bannerPixelSnap: settings.oilBannerPixelSnap,
      autoTextSpacing: settings.oilAutoTextSpacing,
      bannerLetterSpacing: settings.oilBannerLetterSpacing,
      bannerWordSpacing: settings.oilBannerWordSpacing,
      flatLineSpacing: settings.oilFlatLineSpacing,
      scaleSource: settings.oilScaleSource,
      scaleMultiplier: settings.oilScaleMultiplier,
      scaleSineEnabled: settings.oilScaleSineEnabled,
      scaleSineFreq: settings.oilScaleSineFreq,
      scaleSineAmp: settings.oilScaleSineAmp,
      colorSource: settings.oilColorSource,
      colorMultiplier: settings.oilColorMultiplier,
      woodstockEveryHour: settings.oilWoodstockEveryHour,
    );

    final screenSize = MediaQuery.sizeOf(context);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final bool limit4k =
        deviceService.isLowEndTvDevice && screenSize.height > 1080;

    Widget visualizer = StealVisualizer(
      config: config,
      audioReactor: _audioReactor,
      onExit: () => Navigator.of(context).pop(),
      debugAudioSessionId: _debugAudioSessionId,
    );

    if (limit4k) {
      visualizer = FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: 1920, height: 1080, child: visualizer),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(backgroundColor: Colors.black, body: visualizer),
    );
  }
}
