import 'dart:io';
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
      MaterialPageRoute(
        builder: (context) => const ScreensaverScreen(),
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

    if (!settings.oilEnableAudioReactivity) {
      final reactor = await AudioReactorFactory.create();
      if (mounted) setState(() => _audioReactor = reactor);
      return;
    }

    if (Platform.isAndroid) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final sessionId = audioProvider.audioPlayer.androidAudioSessionId;
      final isAvailable = await VisualizerAudioReactor.isAvailable();

      if (isAvailable) {
        final reactor =
            await AudioReactorFactory.create(audioSessionId: sessionId);
        if (mounted) {
          setState(() => _audioReactor = reactor);
          _pushAudioConfig();
        }
      } else {
        final reactor = await AudioReactorFactory.create();
        if (mounted) setState(() => _audioReactor = reactor);
      }
    } else {
      final reactor = await AudioReactorFactory.create();
      if (mounted) setState(() => _audioReactor = reactor);
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _pushAudioConfig());

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
      logoTrailIntensity: settings.oilLogoTrailIntensity,
      logoTrailSlices: settings.oilLogoTrailSlices,
      logoTrailLength: settings.oilLogoTrailLength,
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
