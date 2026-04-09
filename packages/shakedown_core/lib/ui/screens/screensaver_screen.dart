import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/song_structure_hints.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/song_structure_hint_service.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/ui/navigation/route_names.dart';
import 'package:shakedown_core/ui/screens/screensaver/audio_capture_controller.dart';
import 'package:shakedown_core/ui/screens/screensaver/microphone_permission_flow.dart';
import 'package:shakedown_core/ui/screens/screensaver/screensaver_banner_text.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';

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
  final ScreensaverAudioCaptureController _audioCaptureController =
      ScreensaverAudioCaptureController();
  final MicrophonePermissionFlow _microphonePermissionFlow =
      MicrophonePermissionFlow();
  WakelockService? _wakelockService;
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
    if (_audioCaptureController.audioReactor is! VisualizerAudioReactor) {
      return;
    }
    final reactor =
        _audioCaptureController.audioReactor as VisualizerAudioReactor;

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

  Future<void> _syncStereoCapture(SettingsProvider settings) async {
    await _audioCaptureController.syncStereoCapture(
      settings,
      allowPermissionPrompts: widget.allowPermissionPrompts,
      runPermissionFlow: _microphonePermissionFlow.runPermissionFlow,
      mounted: mounted,
    );
  }

  Future<void> _stopStereoCapture({bool resetAttempt = false}) async {
    await _audioCaptureController.stopStereoCapture(resetAttempt: resetAttempt);
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
    if (_microphonePermissionFlow.isPermissionFlowActive ||
        _microphonePermissionFlow.isPermissionFlowCooldown) {
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    await _audioCaptureController.initAudioReactor(
      settings: settings,
      audioProvider: audioProvider,
      isTv: deviceService.isTv,
      allowPermissionPrompts: widget.allowPermissionPrompts,
      mounted: mounted,
      permissionFlow: _microphonePermissionFlow,
      clearPushedAudioConfig: _clearPushedAudioConfig,
      pushAudioConfig: _pushAudioConfig,
      retryInitAudioReactor: ({bool isRetry = false}) =>
          _initAudioReactor(isRetry: isRetry),
      onAudioReactorChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      isRetry: isRetry,
    );
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

  void _ensureAudioReactorState(SettingsProvider settings) {
    if (kIsWeb || !settings.oilEnableAudioReactivity) {
      if (_audioCaptureController.audioReactor != null) {
        unawaited(_stopStereoCapture(resetAttempt: true));
        _audioCaptureController.audioReactor?.dispose();
        _audioCaptureController.audioReactor = null;
        _clearPushedAudioConfig();
      }
      return;
    }

    if (_audioCaptureController.audioReactor == null &&
        !_audioCaptureController.isInitializingAudioReactor) {
      _initAudioReactor();
    }
  }

  String _composeBannerText(SettingsProvider settings, AudioProvider audio) {
    return composeScreensaverBannerText(
      showInfoBanner: settings.oilShowInfoBanner,
      title: audio.currentTrack?.title,
    );
  }

  String _composeVenue(SettingsProvider settings, AudioProvider audio) {
    return composeScreensaverVenue(
      showInfoBanner: settings.oilShowInfoBanner,
      venue: audio.currentShow?.venue,
    );
  }

  String _composeDate(SettingsProvider settings, AudioProvider audio) {
    return composeScreensaverDate(
      showInfoBanner: settings.oilShowInfoBanner,
      date: audio.currentShow?.date,
    );
  }

  @override
  void dispose() {
    _microphonePermissionFlow.dispose();
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _wakelockService?.disable();
    // Preserve Enhanced capture across screensaver launches for the life of
    // the app session. It is still torn down when audio reactivity is
    // disabled, the detector switches away from Enhanced, or the activity
    // itself is destroyed.
    _audioCaptureController.dispose(
      clearPushedAudioConfig: _clearPushedAudioConfig,
    );
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
    if (_audioCaptureController.audioReactor != null &&
        defaultTargetPlatform == TargetPlatform.android) {
      final freshId = audioProvider.audioPlayer.androidAudioSessionId;
      if (freshId != null &&
          freshId > 0 &&
          (_audioCaptureController.debugAudioSessionId == null ||
              _audioCaptureController.debugAudioSessionId == 0)) {
        _audioCaptureController.debugAudioSessionId = freshId;
        _initAudioReactor(isRetry: true);
      }
    }

    if (_audioCaptureController.audioReactor != null) {
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
      audioReactor: _audioCaptureController.audioReactor,
      onExit: () => Navigator.of(context).pop(),
      debugAudioSessionId: _audioCaptureController.debugAudioSessionId,
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
