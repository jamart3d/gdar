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

  bool _handleGlobalKeyEvent(KeyEvent event) {
    // Exit screensaver on any key down event
    if (event is KeyDownEvent) {
      if (mounted) {
        Navigator.of(context).pop();
        return true; // Handled
      }
    }
    return false;
  }

  Future<void> _initAudioReactor() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.oilEnableAudioReactivity) {
      // Audio reactivity disabled
      final reactor = await AudioReactorFactory.create();
      if (mounted) {
        setState(() => _audioReactor = reactor);
      }
      return;
    }

    // Try to use Android Visualizer API if available
    if (Platform.isAndroid) {
      // Get audio session ID from audio player BEFORE the async gap
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final sessionId = audioProvider.audioPlayer.androidAudioSessionId;

      final isAvailable = await VisualizerAudioReactor.isAvailable();

      if (isAvailable) {
        final reactor = await AudioReactorFactory.create(
          audioSessionId: sessionId,
        );

        if (mounted) {
          setState(() => _audioReactor = reactor);
        }
      } else {
        // Fallback to mock
        final reactor = await AudioReactorFactory.create();
        if (mounted) {
          setState(() => _audioReactor = reactor);
        }
      }
    } else {
      // Non-Android platforms use mock
      final reactor = await AudioReactorFactory.create();
      if (mounted) {
        setState(() => _audioReactor = reactor);
      }
    }
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

    // Build config from settings
    final config = StealConfig(
      flowSpeed: settings.oilFlowSpeed,
      palette: settings.oilPalette,
      filmGrain: settings.oilFilmGrain,
      pulseIntensity: settings.oilPulseIntensity,
      heatDrift: settings.oilHeatDrift,
      enableAudioReactivity: settings.oilEnableAudioReactivity,
      performanceMode: settings.oilPerformanceMode ||
          Provider.of<DeviceService>(context, listen: false).isTv,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // No extra logic needed
      },
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
