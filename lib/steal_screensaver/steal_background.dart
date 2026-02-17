import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

class StealBackground extends PositionComponent
    with HasGameReference<StealGame> {
  StealConfig config;
  ui.FragmentShader? _shader;
  ui.Image? _logoTexture;
  bool _shaderLoaded = false;
  String? _loadError;

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    await _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      // Load Shader
      final program = await ui.FragmentProgram.fromAsset('shaders/steal.frag');
      _shader = program.fragmentShader();

      // Load Texture
      _logoTexture = await game.images.load('t_steal_ss.png');

      _shaderLoaded = true;
    } catch (e) {
      _loadError = e.toString();
      debugPrint('Steal Screensaver Load Error: $e');
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
  }

  @override
  void render(Canvas canvas) {
    if (!_shaderLoaded ||
        _shader == null ||
        _logoTexture == null ||
        size.x <= 10 ||
        size.y <= 10) {
      _renderFallback(canvas);
      return;
    }

    _updateShaderUniforms();

    final paint = Paint()..shader = _shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  void _updateShaderUniforms() {
    if (_shader == null) return;

    final energy = game.currentEnergy;
    final time = game.time;

    int idx = 0;
    // Pass resolution with a minimum 1.0 to avoid division by zero in shader
    final sw = size.x.clamp(1.0, 20000.0);
    final sh = size.y.clamp(1.0, 20000.0);
    _shader!.setFloat(idx++, sw);
    _shader!.setFloat(idx++, sh);
    _shader!.setFloat(idx++, time);

    _shader!.setFloat(idx++, config.flowSpeed.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.filmGrain.clamp(0.0, 1.0));
    _shader!.setFloat(idx++, config.pulseIntensity.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.heatDrift.clamp(0.0, 5.0));

    _shader!.setFloat(idx++, energy.bass.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.mid.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.treble.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.overall.clamp(0.0, 5.0));

    final colors = _getPaletteColors(config.palette);
    for (final color in colors) {
      // Use explicit red/255 for maximum compatibility across Flutter versions
      _shader!.setFloat(idx++, color.red / 255.0);
      _shader!.setFloat(idx++, color.green / 255.0);
      _shader!.setFloat(idx++, color.blue / 255.0);
    }

    _shader!.setImageSampler(0, _logoTexture!);
  }

  List<Color> _getPaletteColors(String name) {
    return StealConfig.palettes[name] ?? StealConfig.palettes['psychedelic']!;
  }

  void _renderFallback(Canvas canvas) {
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    if (_loadError != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Steal Screensaver Error:\n$_loadError',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, size.y / 2 - 50));
    }
  }
}
