import 'dart:async';
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
  Timer? _keyboardHandlerTimer; // Added Timer for keyboard handler

  @override
  void initState() {
    super.initState();
    _initAudioReactor();
    // Delay key handler to avoid catching the launch key event on Google TV
    _keyboardHandlerTimer = Timer(const Duration(milliseconds: 500), () {
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
          // Push initial config once reactor is ready
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

  @override
  void dispose() {
    _keyboardHandlerTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _wakelockService?.disable();
    _audioReactor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Push config whenever settings rebuild this widget
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
