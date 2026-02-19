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
    // Delay key handler to avoid catching the launch key event on Google TV
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
      }
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

  /// Push current tuning knob values to the native visualizer.
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
      if (mounted) {
        setState(() => _audioReactor = reactor);
      }
      return;
    }

    if (Platform.isAndroid) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final sessionId = audioProvider.audioPlayer.androidAudioSessionId;
      final isAvailable = await VisualizerAudioReactor.isAvailable();

      if (isAvailable) {
        final reactor = await AudioReactorFactory.create(
          audioSessionId: sessionId,
        );
        if (mounted) {
          setState(() => _audioReactor = reactor);
          _pushAudioConfig();
        }
      } else {
        final reactor = await AudioReactorFactory.create();
        if (mounted) {
          setState(() => _audioReactor = reactor);
        }
      }
    } else {
      final reactor = await AudioReactorFactory.create();
      if (mounted) {
        setState(() => _audioReactor = reactor);
      }
    }
  }

  /// Compose banner text from current track + show metadata.
  /// Format: "Track Title  •  Venue  •  Date"
  /// Returns empty string if nothing is playing or banner is disabled.
  String _composeBannerText(
      SettingsProvider settings, AudioProvider audioProvider) {
    if (!settings.oilShowInfoBanner) return '';

    final track = audioProvider.currentTrack;
    final show = audioProvider.currentShow;

    if (track == null && show == null) return '';

    final parts = <String>[];
    if (track?.title != null && track!.title.isNotEmpty) {
      parts.add(track.title);
    }
    if (show?.venue != null && show!.venue.isNotEmpty) {
      parts.add(show.venue);
    }
    if (show?.date != null && show!.date.isNotEmpty) {
      parts.add(show.date);
    }

    if (parts.isEmpty) return '';

    // Join with spaced bullet separator and add trailing spaces so the
    // circular text wraps cleanly without the end crashing into the start.
    return '${parts.join('  •  ')}     ';
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

    // Push audio config whenever settings rebuild this widget
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushAudioConfig());

    final config = StealConfig(
      flowSpeed: settings.oilFlowSpeed,
      palette: settings.oilPalette,
      pulseIntensity: settings.oilPulseIntensity,
      heatDrift: settings.oilHeatDrift,
      enableAudioReactivity: settings.oilEnableAudioReactivity,
      performanceMode: settings.oilPerformanceMode ||
          Provider.of<DeviceService>(context, listen: false).isTv,
      logoScale: settings.oilLogoScale,
      showInfoBanner: settings.oilShowInfoBanner,
      bannerText: _composeBannerText(settings, audioProvider),
      paletteCycle: settings.oilPaletteCycle,
      paletteTransitionSpeed: settings.oilPaletteTransitionSpeed,
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
