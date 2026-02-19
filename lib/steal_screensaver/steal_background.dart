import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

class StealBackground extends PositionComponent
    with HasGameReference<StealGame> {
  StealConfig config;
  ui.FragmentShader? _shader;
  ui.Image? _logoTexture;
  bool _shaderLoaded = false;

  // Smooth color transition state
  // _currentColors lerps toward _targetColors each frame
  List<Color> _currentColors = [];
  List<Color> _targetColors = [];
  static const double _colorLerpSpeed = 0.025; // ~1s transition at 60fps

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      await _loadResources();
      // Initialise both current and target to the starting palette
      // so there's no lerp-from-black on first load
      final initial = _getPaletteColors(config.palette);
      _currentColors = List.of(initial);
      _targetColors = List.of(initial);
    } catch (_) {
      // Fail silently — _renderFallback paints black
    }
  }

  Future<void> _loadResources() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/steal.frag');
    _shader = program.fragmentShader();

    final data = await rootBundle.load('assets/images/t_steal_ss.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _logoTexture = frame.image;

    _shaderLoaded = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  void updateConfig(StealConfig newConfig) {
    final oldPalette = config.palette;
    config = newConfig;

    // Only update target colors when palette actually changes
    if (newConfig.palette != oldPalette || _targetColors.isEmpty) {
      _targetColors = _getPaletteColors(newConfig.palette);
      // If currentColors not yet initialised, snap immediately
      if (_currentColors.isEmpty) {
        _currentColors = List.of(_targetColors);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Lerp each color channel toward target
    if (_currentColors.length == _targetColors.length) {
      for (int i = 0; i < _currentColors.length; i++) {
        _currentColors[i] = Color.lerp(
          _currentColors[i],
          _targetColors[i],
          _colorLerpSpeed,
        )!;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (!_shaderLoaded ||
        _shader == null ||
        _logoTexture == null ||
        size.x <= 10 ||
        size.y <= 10) {
      _renderFallback(canvas);
      return;
    }

    _updateShaderUniforms();

    final paint = ui.Paint()..shader = _shader;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  void _updateShaderUniforms() {
    if (_shader == null) return;

    final energy = game.currentEnergy;
    final time = game.time;

    int idx = 0;
    final sw = size.x.clamp(1.0, 20000.0);
    final sh = size.y.clamp(1.0, 20000.0);
    _shader!.setFloat(idx++, sw);
    _shader!.setFloat(idx++, sh);
    _shader!.setFloat(idx++, time);

    _shader!.setFloat(idx++, config.flowSpeed.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.filmGrain.clamp(0.0, 1.0));
    _shader!.setFloat(idx++, config.pulseIntensity.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.heatDrift.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.logoScale.clamp(0.05, 1.0));

    _shader!.setFloat(idx++, energy.bass.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.mid.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.treble.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.overall.clamp(0.0, 5.0));

    // Use lerped colors for smooth transitions
    final colors = _currentColors.isNotEmpty
        ? _currentColors
        : _getPaletteColors(config.palette);

    for (final color in colors) {
      _shader!.setFloat(idx++, color.r);
      _shader!.setFloat(idx++, color.g);
      _shader!.setFloat(idx++, color.b);
    }

    _shader!.setImageSampler(0, _logoTexture!);
  }

  List<Color> _getPaletteColors(String name) {
    return StealConfig.palettes[name] ?? StealConfig.palettes['psychedelic']!;
  }

  void _renderFallback(ui.Canvas canvas) {
    canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFF000000));
  }
}
