import 'dart:ui';
import 'package:flame/game.dart';
import 'package:shakedown/oil_slide/oil_slide_config.dart';
import 'package:shakedown/oil_slide/oil_slide_audio_reactor.dart';
import 'package:shakedown/oil_slide/oil_slide_shader_background.dart';

/// Flame game component for the oil_slide visualizer.
///
/// This game manages the rendering loop and coordinates between:
/// - Audio energy data from the reactor
/// - Visual parameters from the config
/// - Shader-based rendering
class OilSlideGame extends FlameGame {
  OilSlideConfig config;
  final OilSlideAudioReactor? audioReactor;
  final dynamic
      deviceService; // Using dynamic to avoid hard dependency on DeviceService here if it's awkward, but actually let's use the type.
  final VoidCallback? onPaletteCycleRequested;

  AudioEnergy _currentEnergy = const AudioEnergy.zero();
  double _time = 0.0;
  OilSlideShaderBackground? _background;

  // Palette Cycling State
  double _accumulatedCycleEnergy = 0.0;
  double _lastCycleTime = 0.0;
  static const double kCycleEnergyThreshold = 100.0; // Energy required to cycle
  static const double kMinCycleInterval =
      10.0; // Minimum seconds between cycles

  OilSlideGame({
    required this.config,
    this.audioReactor,
    this.deviceService,
    this.onPaletteCycleRequested,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Listen to audio energy updates
    audioReactor?.energyStream.listen((energy) {
      _currentEnergy = energy;
    });

    // Add shader background component
    _background = OilSlideShaderBackground(
      config: config,
      game: this,
    );
    await add(_background!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Handle Palette Cycling
    if (config.visualMode == 'steal' && onPaletteCycleRequested != null) {
      // Accumulate energy (bass is most "beat" oriented)
      _accumulatedCycleEnergy += _currentEnergy.bass * dt * 20.0;
      // Also accumulate time slowly
      _accumulatedCycleEnergy += dt * 2.0;

      if (_accumulatedCycleEnergy >= kCycleEnergyThreshold &&
          (_time - _lastCycleTime) >= kMinCycleInterval) {
        _accumulatedCycleEnergy = 0.0;
        _lastCycleTime = _time;
        onPaletteCycleRequested?.call();
      }
    }
  }

  /// Update configuration and propagate to background component
  void updateConfig(OilSlideConfig newConfig) {
    config = newConfig;
    _background?.updateConfig(newConfig);
  }

  /// Get current audio energy for use by components
  AudioEnergy get currentEnergy => _currentEnergy;

  /// Get current time for animations
  double get time => _time;
}
