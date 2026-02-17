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
    _shader!.setFloat(idx++, size.x);
    _shader!.setFloat(idx++, size.y);
    _shader!.setFloat(idx++, time);

    _shader!.setFloat(idx++, config.flowSpeed);
    _shader!.setFloat(idx++, config.filmGrain);
    _shader!.setFloat(idx++, config.pulseIntensity);
    _shader!.setFloat(idx++, config.heatDrift);

    _shader!.setFloat(idx++, energy.bass);
    _shader!.setFloat(idx++, energy.mid);
    _shader!.setFloat(idx++, energy.treble);
    _shader!.setFloat(idx++, energy.overall);

    final colors = _getPaletteColors(config.palette);
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
