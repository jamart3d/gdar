import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/oil_slide/oil_slide_config.dart';
import 'package:shakedown/oil_slide/oil_slide_game.dart';

/// Shader-based background component for oil_slide effect.
///
/// This component loads and renders the GLSL fragment shader with
/// all configuration parameters and audio energy data.
class OilSlideShaderBackground extends PositionComponent {
  OilSlideConfig config;
  final OilSlideGame game;
  ui.FragmentShader? _shader;
  bool _shaderLoaded = false;
  String? _loadError;

  OilSlideShaderBackground({
    required this.config,
    required this.game,
  });

  /// Update configuration for live parameter changes
  void updateConfig(OilSlideConfig newConfig) {
    config = newConfig;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    await _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/oil_slide.frag');
      _shader = program.fragmentShader();
      _shaderLoaded = true;
    } catch (e) {
      _loadError = e.toString();
      _shaderLoaded = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_shaderLoaded || _shader == null) {
      // Fallback: render error or placeholder
      _renderFallback(canvas);
      return;
    }

    // Update shader uniforms
    _updateShaderUniforms();

    // Create paint with shader
    final paint = Paint()..shader = _shader;

    // Draw full screen rect
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  void _renderFallback(Canvas canvas) {
    // Draw error message or simple gradient fallback
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    if (_loadError != null) {
      // Draw error text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Shader Error:\n$_loadError',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, size.y / 2 - 50));
    }
  }

  static const Map<String, List<Color>> _palettes = {
    'psychedelic': [
      Color(0xFFFF00FF),
      Color(0xFF00FFFF),
      Color(0xFFFFFF00),
      Color(0xFFFF0000),
    ],
    'acid_green': [
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF00FF7F),
      Color(0xFF7FFF00),
    ],
    'lava_gold': [
      Color(0xFFFF4500),
      Color(0xFFFFD700),
      Color(0xFFFF8C00),
      Color(0xFFFF6347),
    ],
    // Lava Lamp Mode Palettes
    'lava_classic': [
      Color(0xFF1a0505), // Very Dark Red (Background)
      Color(0xFFd40000), // Vibrant Red
      Color(0xFFFF5500), // Bright Orange
      Color(0xFFFFcc00), // Yellow (Highlights)
    ],
    'purple_haze': [
      Color(0xFF4B0082), // Indigo
      Color(0xFF8B008B), // Dark magenta
      Color(0xFFBA55D3), // Medium orchid
      Color(0xFFDA70D6), // Orchid
    ],
    // Silk Mode Palettes
    'ocean': [
      Color(0xFF000080), // Navy
      Color(0xFF0000CD), // Medium blue
      Color(0xFF00CED1), // Dark turquoise
      Color(0xFF40E0D0), // Turquoise
    ],
    'pearl': [
      Color(0xFFe6e2d8), // Champagne / Off-white
      Color(0xFFc7c2b8), // Silver / Grey
      Color(0xFFa69f91), // Darker Champagne shadow
      Color(0xFF8c8577), // Deep shadow
    ],
    'aurora': [
      Color(0xFF00008B), // Dark Blue
      Color(0xFF00FF7F), // Spring Green
      Color(0xFF9400D3), // Dark Violet
      Color(0xFF1E90FF), // Dodger Blue
    ],
    'deep_blue': [
      Color(0xFF0000FF),
      Color(0xFF0080FF),
      Color(0xFF00FFFF),
      Color(0xFF4B0082),
    ],
    'sunset': [
      Color(0xFFFF7E5F),
      Color(0xFFFEB47B),
      Color(0xFFFFC371),
      Color(0xFFFF5F6D),
    ],
    'cosmic': [
      Color(0xFF0000FF), // Deep Blue
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF4500), // Orange Red
      Color(0xFF00FFFF), // Cyan
    ],
  };

  @override
  void update(double dt) {
    super.update(dt);
    size = game.size;
  }

  List<Color> _getPaletteColors(String palette) {
    return _palettes[palette] ?? _palettes['psychedelic']!;
  }

  void _updateShaderUniforms() {
    if (_shader == null) return;

    final energy = game.currentEnergy;
    final time = game.time;

    int uniformIndex = 0;

    // Screen uniforms
    _shader!.setFloat(uniformIndex++, size.x); // uResolution.x
    _shader!.setFloat(uniformIndex++, size.y); // uResolution.y
    _shader!.setFloat(uniformIndex++, time); // uTime

    // Configuration uniforms
    _shader!.setFloat(uniformIndex++, config.viscosity); // uViscosity
    _shader!.setFloat(uniformIndex++, config.flowSpeed); // uFlowSpeed
    _shader!.setFloat(uniformIndex++, config.filmGrain); // uFilmGrain
    _shader!.setFloat(uniformIndex++, config.pulseIntensity); // uPulseIntensity
    _shader!.setFloat(uniformIndex++, config.heatDrift); // uHeatDrift

    // Audio energy uniforms
    _shader!.setFloat(uniformIndex++, energy.bass); // uBassEnergy
    _shader!.setFloat(uniformIndex++, energy.mid); // uMidEnergy
    _shader!.setFloat(uniformIndex++, energy.treble); // uTrebleEnergy
    _shader!.setFloat(uniformIndex++, energy.overall); // uOverallEnergy

    // Palette color uniforms (RGB)
    final colors = _getPaletteColors(config.palette);
    for (final color in colors) {
      _shader!.setFloat(uniformIndex++, color.r);
      _shader!.setFloat(uniformIndex++, color.g);
      _shader!.setFloat(uniformIndex++, color.b);
    }

    // Metaball count uniform
    _shader!.setFloat(
        uniformIndex++, config.metaballCount.toDouble()); // uMetaballCount

    // Visual Mode uniform (0=lava, 1=silk, 2=psychedelic/custom)
    double modeIndex = 2.0; // Default to psychedelic/custom
    if (config.visualMode == 'lava_lamp') {
      modeIndex = 0.0;
    } else if (config.visualMode == 'silk') {
      modeIndex = 1.0;
    }
    _shader!.setFloat(uniformIndex++, modeIndex); // uVisualMode
  }

  @override
  void onRemove() {
    _shader?.dispose();
    super.onRemove();
  }
}
