import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, HSLColor;
import 'package:flutter/services.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

class StealBackground extends PositionComponent
    with HasGameReference<StealGame> {
  StealConfig config;
  ui.FragmentShader? _shader;
  ui.Image? _logoTexture;
  bool _shaderLoaded = false;

  // Always maintain exactly 4 colors for the shader.
  // Shorter palettes pad with their last color.
  static const int _colorCount = 4;

  List<Color> _currentColors =
      List.filled(_colorCount, const Color(0xFF000000));
  List<Color> _targetColors = List.filled(_colorCount, const Color(0xFF000000));

  double _colorLerpSpeed = 0.025;

  // Smoothed logo position in 0–1 UV space.
  // Lerped each frame toward the raw sin/cos target position.
  // Read by StealBanner via game.smoothedLogoPos to keep rings locked to logo.
  Offset _smoothedPos = const Offset(0.5, 0.5);

  /// Current smoothed logo position (0–1 UV space). Used by StealBanner.
  Offset get smoothedLogoPos => _smoothedPos;

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      await _loadResources();
      final initial = _expandColors(_getPaletteColors(config.palette));
      _currentColors = List.of(initial);
      _targetColors = List.of(initial);
    } catch (_) {}
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

  void overrideTargetColors(List<Color> colors, double lerpSpeed) {
    _colorLerpSpeed = lerpSpeed;
    _targetColors = _expandColors(colors);
    if (_currentColors.isEmpty) {
      _currentColors = List.of(_targetColors);
    }
  }

  void updateConfig(StealConfig newConfig) {
    _applyConfig(newConfig, lerpSpeed: 0.025);
  }

  void updateConfigWithLerpSpeed(StealConfig newConfig, double lerpSpeed) {
    _applyConfig(newConfig, lerpSpeed: lerpSpeed);
  }

  void _applyConfig(StealConfig newConfig, {required double lerpSpeed}) {
    final oldPalette = config.palette;
    config = newConfig;
    _colorLerpSpeed = lerpSpeed;

    if (newConfig.palette != oldPalette || _targetColors.isEmpty) {
      _targetColors = _expandColors(_getPaletteColors(newConfig.palette));
      if (_currentColors.isEmpty) {
        _currentColors = List.of(_targetColors);
      }
      // Ensure current is also always length 4 — prevents lerp skip on mismatch
      if (_currentColors.length != _colorCount) {
        _currentColors = _expandColors(_currentColors);
      }
    }
  }

  /// Pads or trims a color list to exactly [_colorCount] entries.
  /// Shorter lists repeat their last color; longer lists are truncated.
  List<Color> _expandColors(List<Color> colors) {
    if (colors.isEmpty) {
      return List.filled(_colorCount, const Color(0xFFFFFFFF));
    }
    final result = <Color>[];
    for (int i = 0; i < _colorCount; i++) {
      result.add(colors[i < colors.length ? i : colors.length - 1]);
    }
    return result;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Color lerp — both lists guaranteed length 4, never skips
    for (int i = 0; i < _colorCount; i++) {
      if (_currentColors.length > i && _targetColors.length > i) {
        _currentColors[i] = Color.lerp(
          _currentColors[i],
          _targetColors[i],
          _colorLerpSpeed,
        )!;
      }
    }

    // Compute raw logo target position (same formula as shader previously used)
    final safeTime = game.time.clamp(0.0, double.infinity);
    final t = safeTime * config.flowSpeed.clamp(0.0, 2.0) * 0.5;
    final drift = config.orbitDrift.clamp(0.0, 2.0);
    final rawX = 0.5 + 0.25 * drift * sin(t * 1.3) + 0.1 * drift * sin(t * 2.9);
    final rawY = 0.5 + 0.25 * drift * cos(t * 1.7) + 0.1 * drift * cos(t * 3.1);

    // Lerp smoothedPos toward raw pos.
    // translationSmoothing 0.0 = instant (lerpFactor 1.0)
    // translationSmoothing 1.0 = very smooth (lerpFactor 0.02)
    final s = config.translationSmoothing.clamp(0.0, 1.0);
    final lerpFactor = 1.0 - s * 0.98;
    _smoothedPos = Offset(
      _smoothedPos.dx + (rawX - _smoothedPos.dx) * lerpFactor,
      _smoothedPos.dy + (rawY - _smoothedPos.dy) * lerpFactor,
    );
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

    // Draw trail ghost slices before the main shader pass so they sit behind
    if (config.logoTrailIntensity > 0.0 && _logoTexture != null) {
      _renderTrail(canvas);
    }

    _updateShaderUniforms();

    final paint = ui.Paint()..shader = _shader;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  // ── Trail rendering ────────────────────────────────────────────────────────

  void _renderTrail(ui.Canvas canvas) {
    final slices = config.logoTrailSlices.clamp(2, 16);
    final intensity = config.logoTrailIntensity.clamp(0.0, 1.0);
    final positions = game.getTrailPositions(slices);
    if (positions.isEmpty) return;

    final logoTex = _logoTexture!;
    final texW = logoTex.width.toDouble();
    final texH = logoTex.height.toDouble();
    final w = size.x;
    final h = size.y;
    final minDim = min(w, h);

    // Logo render size matches shader: logoScale * minDim
    final logoRenderSize = config.logoScale.clamp(0.05, 1.0) * minDim;

    // Desaturated, darkened tint derived from current palette color
    final baseColor =
        _currentColors.isNotEmpty ? _currentColors[0] : const Color(0xFFFFFFFF);
    final hsl = HSLColor.fromColor(baseColor);
    final ghostTint = hsl
        .withSaturation((hsl.saturation * 0.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0))
        .toColor();

    final srcRect = ui.Rect.fromLTWH(0, 0, texW, texH);

    for (int i = 0; i < positions.length; i++) {
      // i=0 newest (closest), i=slices-1 oldest
      final t = i / slices.toDouble(); // 0.0=newest, 1.0=oldest
      // Quadratic fade: strong near the logo, invisible at the tail
      final opacity = intensity * (1.0 - t) * (1.0 - t) * 0.45;
      if (opacity < 0.01) continue;

      // Slight scale reduction toward older slices
      final scale = 1.0 - t * 0.12;
      final renderSize = logoRenderSize * scale;

      final pos = positions[i];
      final cx = pos.dx * w;
      final cy = pos.dy * h;

      final dst = ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: renderSize,
        height: renderSize * (texH / texW),
      );

      final paint = ui.Paint()
        ..colorFilter = ui.ColorFilter.mode(
          ghostTint.withValues(alpha: opacity),
          ui.BlendMode.modulate,
        );

      // Only blur the 3 newest slices — older ones are too faint to justify cost
      final shouldBlur = i < 3 && config.blurAmount > 0.0;

      if (shouldBlur) {
        final sigma = config.blurAmount * 4.0 * (1.0 - t);
        if (sigma > 0.5) {
          final blurPaint = ui.Paint()
            ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
          canvas.saveLayer(dst.inflate(sigma * 2), blurPaint);
          canvas.drawImageRect(logoTex, srcRect, dst, paint);
          canvas.restore();
          continue;
        }
      }

      canvas.drawImageRect(logoTex, srcRect, dst, paint);
    }
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

    // Uniform index order must match steal.frag declarations exactly:
    // flowSpeed(3) filmGrain(4) pulseIntensity(5) heatDrift(6)
    // logoScale(7) blurAmount(8) flatColor(9)
    // logoPosX(10) logoPosY(11)
    // bass(12) mid(13) treble(14) overall(15)
    // color1(16-18) color2(19-21) color3(22-24) color4(25-27)
    _shader!.setFloat(idx++, config.flowSpeed.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, 0.0); // filmGrain hardcoded off
    _shader!.setFloat(idx++, config.pulseIntensity.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.heatDrift.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.logoScale.clamp(0.05, 1.0));
    _shader!.setFloat(idx++, config.blurAmount.clamp(0.0, 1.0));
    _shader!.setFloat(idx++, config.flatColor ? 1.0 : 0.0);
    _shader!.setFloat(idx++, _smoothedPos.dx); // uLogoPosX
    _shader!.setFloat(idx++, _smoothedPos.dy); // uLogoPosY

    _shader!.setFloat(idx++, energy.bass.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.mid.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.treble.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, energy.overall.clamp(0.0, 5.0));

    // Always write exactly 4 colors — shader always expects uColor1–uColor4
    final colors = _currentColors.length == _colorCount
        ? _currentColors
        : _expandColors(_getPaletteColors(config.palette));

    for (final color in colors) {
      _shader!.setFloat(idx++, color.r);
      _shader!.setFloat(idx++, color.g);
      _shader!.setFloat(idx++, color.b);
    }

    _shader!.setImageSampler(0, _logoTexture!);
  }

  List<Color> _getPaletteColors(String name) {
    return StealConfig.palettes[name] ?? StealConfig.palettes.values.first;
  }

  void _renderFallback(ui.Canvas canvas) {
    canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFF000000));
  }
}
