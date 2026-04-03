import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/ui/navigation/app_route_observer.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/visualizer/audio_reactor_factory.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';

class TvScreensaverPreviewPanel extends StatefulWidget {
  const TvScreensaverPreviewPanel({super.key});

  @override
  State<TvScreensaverPreviewPanel> createState() =>
      _TvScreensaverPreviewPanelState();
}

class _TvScreensaverPreviewPanelState extends State<TvScreensaverPreviewPanel>
    with RouteAware {
  AudioReactor? _previewReactor;
  int? _previewAudioSessionId;
  ModalRoute<dynamic>? _route;
  bool _isRouteCurrent = true;
  bool _isInitializingPreviewReactor = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initPreviewReactor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) {
      return;
    }
    if (_route != null) {
      shakedownRouteObserver.unsubscribe(this);
    }
    _route = route;
    if (route != null) {
      shakedownRouteObserver.subscribe(this, route);
      _isRouteCurrent = route.isCurrent;
      if (!_isRouteCurrent) {
        unawaited(_disposePreviewReactor());
      }
    }
  }

  Future<void> _initPreviewReactor() async {
    if (_isInitializingPreviewReactor || _previewReactor != null) return;
    if (!mounted) return;
    if (!_isRouteCurrent) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (kIsWeb) return;

    _isInitializingPreviewReactor = true;
    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      int? sessionId;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final audioProvider = Provider.of<AudioProvider>(
          context,
          listen: false,
        );
        sessionId = audioProvider.audioPlayer.androidAudioSessionId;
        _previewAudioSessionId = sessionId;
      }

      final reactor = await AudioReactorFactory.create(
        audioSessionId: sessionId,
        isTv: deviceService.isTv,
      );

      if (reactor != null) {
        if (!mounted || !_isRouteCurrent) {
          reactor.dispose();
          return;
        }
        final started = await reactor.start();
        if (!started) {
          reactor.dispose();
        } else if (mounted && _isRouteCurrent) {
          setState(() => _previewReactor = reactor);
          if (reactor is VisualizerAudioReactor) {
            reactor.updateConfig(
              peakDecay: settings.oilAudioPeakDecay,
              bassBoost: settings.oilAudioBassBoost,
              reactivityStrength: settings.oilAudioReactivityStrength,
              beatDetectorMode: settings.oilBeatDetectorMode,
              beatSensitivity: settings.oilBeatSensitivity,
            );
          }
        } else {
          reactor.dispose();
        }
      }
    } finally {
      _isInitializingPreviewReactor = false;
    }
  }

  Future<void> _disposePreviewReactor() async {
    final reactor = _previewReactor;
    if (reactor == null) return;
    _previewReactor = null;
    logger.i('TvScreensaverPreviewPanel: disposing preview reactor');
    if (reactor is VisualizerAudioReactor) {
      await reactor.stop();
    } else {
      reactor.stop();
    }
    reactor.dispose();
  }

  @override
  void didPush() {
    _isRouteCurrent = true;
  }

  @override
  void didPopNext() {
    _isRouteCurrent = true;
    Future.microtask(_initPreviewReactor);
  }

  @override
  void didPushNext() {
    _isRouteCurrent = false;
    unawaited(_disposePreviewReactor());
  }

  @override
  void didPop() {
    _isRouteCurrent = false;
    unawaited(_disposePreviewReactor());
  }

  @override
  void dispose() {
    shakedownRouteObserver.unsubscribe(this);
    unawaited(_disposePreviewReactor());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    if (!settings.useOilScreensaver || !settings.oilEnableAudioReactivity) {
      return const SizedBox.shrink();
    }

    if (_previewReactor is VisualizerAudioReactor) {
      (_previewReactor as VisualizerAudioReactor).updateConfig(
        peakDecay: settings.oilAudioPeakDecay,
        bassBoost: settings.oilAudioBassBoost,
        reactivityStrength: settings.oilAudioReactivityStrength,
        beatDetectorMode: settings.oilBeatDetectorMode,
        beatSensitivity: settings.oilBeatSensitivity,
      );
    }

    final config = StealConfig(
      flowSpeed: settings.oilFlowSpeed,
      palette: settings.oilPalette,
      filmGrain: settings.oilFilmGrain,
      pulseIntensity: settings.oilPulseIntensity,
      heatDrift: settings.oilHeatDrift,
      enableAudioReactivity: settings.oilEnableAudioReactivity,
      performanceLevel: settings.oilPerformanceLevel,
      logoScale: settings.oilPreviewShowGraph ? 0.0 : settings.oilLogoScale,
      translationSmoothing: settings.oilTranslationSmoothing,
      blurAmount: settings.oilBlurAmount,
      flatColor: settings.oilFlatColor,
      bannerGlow: settings.oilBannerGlow,
      bannerFlicker: settings.oilBannerFlicker,
      showInfoBanner: false,
      bannerText: '',
      venue: '',
      date: '',
      trackHintId: '',
      trackHintTitle: '',
      trackHintVariant: '',
      trackHintSeedSource: 'audio',
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
      audioGraphMode: settings.oilPreviewShowGraph
          ? settings.oilAudioGraphMode
          : 'off',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: StealVisualizer(
                config: config,
                audioReactor: _previewReactor,
                debugAudioSessionId: _previewAudioSessionId,
              ),
            ),
          ),
        );
      },
    );
  }
}
