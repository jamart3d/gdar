import 'dart:ui';
import 'package:flame/game.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_background.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/services/device_service.dart';

class StealGame extends FlameGame {
  StealConfig config;
  final AudioReactor? audioReactor;
  final DeviceService deviceService;

  StealBackground? _background;
  double _time = 0;
  AudioEnergy _currentEnergy = const AudioEnergy.zero();

  // Palette Cycling State
  double _accumulatedCycleEnergy = 0.0;
  double _lastCycleTime = 0.0;
  static const double kCycleEnergyThreshold = 100.0;
  static const double kMinCycleInterval = 10.0;
  final VoidCallback? onPaletteCycleRequested;

  StealGame({
    required this.config,
    this.audioReactor,
    required this.deviceService,
    this.onPaletteCycleRequested,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Listen to audio energy updates
    audioReactor?.energyStream.listen((energy) {
      _currentEnergy = energy;
    });

    _background = StealBackground(config: config);
    add(_background!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Handle Palette Cycling
    if (onPaletteCycleRequested != null) {
      _accumulatedCycleEnergy += _currentEnergy.bass * dt * 20.0;
      _accumulatedCycleEnergy += dt * 2.0;

      if (_accumulatedCycleEnergy >= kCycleEnergyThreshold &&
          (_time - _lastCycleTime) >= kMinCycleInterval) {
        _accumulatedCycleEnergy = 0.0;
        _lastCycleTime = _time;
        onPaletteCycleRequested?.call();
      }
    }
  }

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
    _background?.updateConfig(newConfig);
  }

  double get time => _time;

  AudioEnergy get currentEnergy => _currentEnergy;
}
