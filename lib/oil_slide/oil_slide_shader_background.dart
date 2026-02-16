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
  ui.Image? _stealTexture;
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
    await Future.wait([
      _loadShader(),
      _loadTextures(),
    ]);
  }

  @override
  void onRemove() {
    _shader?.dispose();
    // Do not dispose the image here as it might be cached by Flame.
    // If we generated a fallback, we should technically dispose it,
    // but a 1x1 image is negligible.
    super.onRemove();
  }

  Future<void> _loadTextures() async {
    try {
      // Load the image using Flame's image cache (accessed via game)
      _stealTexture = await game.images.load('t_steal_ss.png');
    } catch (e) {
      debugPrint('Error loading texture: $e. Generating fallback.');
      _loadError = 'Texture Load Error: $e'; // Keep track of error
      await _generateFallbackTexture();
    }
  }

  Future<void> _generateFallbackTexture() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = const Color(0x00000000); // Transparent
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
      final picture = recorder.endRecording();
      _stealTexture = await picture.toImage(1, 1);
    } catch (e) {
      debugPrint('CRITICAL: Failed to generate fallback texture: $e');
      _loadError = 'Fallback Generation Error: $e';
    }
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
      debugPrint('Shader Load Error: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_shaderLoaded || _shader == null || _stealTexture == null) {
      // Fallback: render error or placeholder
      // We must have a texture bound for the shader to work on strict drivers,
      // even if we don't use it.
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
          text: 'Shader/Texture Error:\n$_loadError',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, size.y / 2 - 50));
    }
  }

  List<Color> _getPaletteColors(String palette) {
    return OilSlideConfig.palettes[palette] ??
        OilSlideConfig.palettes['psychedelic']!;
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
    } else if (config.visualMode == 'steal') {
      modeIndex = 3.0;
    }
    _shader!.setFloat(uniformIndex++, modeIndex); // uVisualMode

    // Performance Mode uniform (0.0=Off, 1.0=On)
    // Auto-enable on TV OR respect manual setting
    final bool performanceMode =
        config.oilPerformanceMode || game.deviceService.isTv;
    _shader!.setFloat(
        uniformIndex++, performanceMode ? 1.0 : 0.0); // uPerformanceMode

    // Sampler uniforms
    // We must bind the texture if we have it, as the shader expects a sampler.
    // Even if we don't sample it in other modes, it's good practice to bind.
    if (_stealTexture != null) {
      _shader!.setImageSampler(0, _stealTexture!);
    } else {
      // Should not happen if fallback generation works, but for safety:
      // We can't do anything here without a texture.
      // If we are strict, we might want to throw or log again.
      // But _loadTextures handles fallback now.
    }
  }
}
