import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/visualizer/audio_reactor_factory.dart';
import 'package:shakedown/visualizer/visualizer_audio_reactor.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/wakelock_service.dart';

/// Screensaver screen displaying the Steal Your Face visualizer.
class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ScreensaverScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  AudioReactor? _audioReactor;
  WakelockService? _wakelockService;

  @override
  void initState() {
    super.initState();
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
    _pushAudioConfig();
  }

  void _pushAudioConfig() {
    if (_audioReactor is VisualizerAudioReactor) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      (_audioReactor as VisualizerAudioReactor).updateConfig(
        peakDecay: settings.oilAudioPeakDecay,
        bassBoost: settings.oilAudioBassBoost,
        reactivityStrength: settings.oilAudioReactivityStrength,
        beatSensitivity: settings.oilBeatSensitivity,
      );
    }
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (mounted) {
        Navigator.of(context).pop();
        return true;
      }
    }
    return false;
  }

  Future<void> _initAudioReactor() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final deviceService = Provider.of<DeviceService>(context, listen: false);

    // Skip if audio reactivity is disabled or on Web
    if (kIsWeb || !settings.oilEnableAudioReactivity) {
      final reactor =
          await AudioReactorFactory.create(isTv: deviceService.isTv);
      if (mounted) {
        setState(() => _audioReactor = reactor);
        reactor.start();
      }
      return;
    }

    int? sessionId;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      sessionId = audioProvider.audioPlayer.androidAudioSessionId;
    }

    // Factory handles logic: only returns real visualizer if isTv is true AND on Android
    final reactor = await AudioReactorFactory.create(
      audioSessionId: sessionId,
      isTv: deviceService.isTv,
    );

    if (mounted) {
      setState(() => _audioReactor = reactor);
      // If we successfully got a real visualizer, push initial config
      if (reactor is VisualizerAudioReactor) {
        _pushAudioConfig();
      }
      reactor.start();
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
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _wakelockService?.disable();
    _audioReactor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();

    final config = StealConfig(
      flowSpeed: settings.oilFlowSpeed,
      palette: settings.oilPalette,
      filmGrain: settings.oilFilmGrain,
      pulseIntensity: settings.oilPulseIntensity,
      heatDrift: settings.oilHeatDrift,
      enableAudioReactivity: settings.oilEnableAudioReactivity,
      performanceMode: settings.oilPerformanceMode ||
          Provider.of<DeviceService>(context, listen: false).isTv,
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
      logoTrailLength: settings.oilLogoTrailLength,
      flatTextProximity: settings.oilFlatTextProximity,
      flatTextPlacement: settings.oilFlatTextPlacement,
      audioGraphMode: settings.oilAudioGraphMode,
      beatSensitivity: settings.oilBeatSensitivity,
      innerRingFontScale: settings.oilInnerRingFontScale,
      innerRingSpacingMultiplier: settings.oilInnerRingSpacingMultiplier,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StealVisualizer(
          config: config,
          audioReactor: _audioReactor,
          onExit: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
