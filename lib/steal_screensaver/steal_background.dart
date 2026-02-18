import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

class StealBackground extends PositionComponent
    with HasGameReference<StealGame> {
  StealConfig config;
  ui.FragmentShader? _shader;
  ui.Image? _logoTexture;
  bool _shaderLoaded = false;

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    try {
      await _loadResources();
    } catch (_) {
      // Fail silently — _renderFallback paints black
    }
  }

  Future<void> _loadResources() async {
    try {
      // Load shader
      final program = await ui.FragmentProgram.fromAsset('shaders/steal.frag');
      _shader = program.fragmentShader();

      // Load texture via rootBundle to avoid Flame image cache path issues
      final ByteData data =
          await rootBundle.load('assets/images/t_steal_ss.png');
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      _logoTexture = frame.image;

      _shaderLoaded = true;
    } catch (e) {
      // Fail silently — _renderFallback paints black
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
    // Always paint black — never let white show through
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x.clamp(1, 20000), size.y.clamp(1, 20000)),
      Paint()..color = const Color(0xFF000000),
    );
  }
}
