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

  AudioEnergy _currentEnergy = const AudioEnergy.zero();
  double _time = 0.0;
  OilSlideShaderBackground? _background;

  OilSlideGame({
    required this.config,
    this.audioReactor,
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
