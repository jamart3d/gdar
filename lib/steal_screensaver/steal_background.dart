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

  /// Beat pulse accumulator: 0.0→1.0, spikes on beat, decays per frame.
  double _beatPulse = 0.0;

  /// Current smoothed logo position (0–1 UV space). Used by StealBanner.
  Offset get smoothedLogoPos => _smoothedPos;

  // Random phase offset applied to motion path so each session starts at a
  // different point on the curve and traces a visually distinct path.
  // Randomised once in onLoad, never changes during a session.
  late final double _phaseOffset;

  // Small random frequency nudges so the Lissajous curve shape itself varies
  // slightly each session — prevents the path ever looking identical.
  late final double _freqNudgeX1;
  late final double _freqNudgeY1;
  late final double _freqNudgeX2;
  late final double _freqNudgeY2;

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Randomise motion path for this session
    final rng = Random();
    _phaseOffset =
        rng.nextDouble() * 2 * pi * 10; // random start anywhere on curve
    _freqNudgeX1 = 1.3 + (rng.nextDouble() - 0.5) * 0.3; // 1.15 – 1.45
    _freqNudgeY1 = 1.7 + (rng.nextDouble() - 0.5) * 0.3; // 1.55 – 1.85
    _freqNudgeX2 = 2.9 + (rng.nextDouble() - 0.5) * 0.4; // 2.70 – 3.10
    _freqNudgeY2 = 3.1 + (rng.nextDouble() - 0.5) * 0.4; // 2.90 – 3.30

    try {
      await _loadResources();
      final initial = _expandColors(_getPaletteColors(config.palette));
      _currentColors = List.of(initial);
      _targetColors = List.of(initial);

      // Initialize logo to its correct starting position on the path
      final t = _phaseOffset * config.flowSpeed.clamp(0.0, 2.0) * 0.5;
      final drift = config.orbitDrift.clamp(0.0, 2.0);
      final startX = 0.5 +
          0.25 * drift * sin(t * _freqNudgeX1) +
          0.1 * drift * sin(t * _freqNudgeX2);
      final startY = 0.5 +
          0.25 * drift * cos(t * _freqNudgeY1) +
          0.1 * drift * cos(t * _freqNudgeY2);
      _smoothedPos = Offset(startX, startY);
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

    // Color lerp — time corrected for frame-rate independence
    // _colorLerpSpeed is based on 60fps frame factor
    final colorAlpha = 1.0 - pow(1.0 - _colorLerpSpeed, dt * 60);

    for (int i = 0; i < _colorCount; i++) {
      if (_currentColors.length > i && _targetColors.length > i) {
        _currentColors[i] = Color.lerp(
          _currentColors[i],
          _targetColors[i],
          colorAlpha,
        )!;
      }
    }

    // Compute raw logo target position.
    // _phaseOffset randomised at init so each session starts at a different
    // point. _freqNudge values vary the curve shape slightly each session.
    final safeTime = game.time.clamp(0.0, double.infinity);
    final t =
        (safeTime + _phaseOffset) * config.flowSpeed.clamp(0.0, 2.0) * 0.5;
    final drift = config.orbitDrift.clamp(0.0, 2.0);
    final rawX = 0.5 +
        0.25 * drift * sin(t * _freqNudgeX1) +
        0.1 * drift * sin(t * _freqNudgeX2);
    final rawY = 0.5 +
        0.25 * drift * cos(t * _freqNudgeY1) +
        0.1 * drift * cos(t * _freqNudgeY2);

    // Lerp smoothedPos toward raw pos using time-based decay
    final s = config.translationSmoothing.clamp(0.0, 1.0);
    // Base alpha per frame (approx 60fps).
    // s=0 -> baseAlpha=1 (instant). s=1 -> baseAlpha=0.01 (very slow).
    final baseAlpha = 1.0 - s * 0.99;
    // Time-corrected alpha: 1 - (1 - base)^dt_ratio
    final posAlpha = 1.0 - pow(1.0 - baseAlpha, dt * 60);

    _smoothedPos = Offset(
      _smoothedPos.dx + (rawX - _smoothedPos.dx) * posAlpha,
      _smoothedPos.dy + (rawY - _smoothedPos.dy) * posAlpha,
    );

    // Beat pulse: spike on beat, exponential decay
    final energy = game.currentEnergy;
    if (energy.isBeat) {
      _beatPulse = 1.0;
    } else {
      // Decay ~90% per 0.2s at 60fps: factor ≈ 0.96 per frame
      _beatPulse *= pow(0.04, dt).clamp(0.0, 1.0).toDouble();
      if (_beatPulse < 0.01) _beatPulse = 0.0;
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

    // Draw trail ghost slices AFTER the shader so they appear in front of
    // the background but are then composited — ghosts sit between background
    // and the live logo which the shader draws on top.
    // Note: shader renders the logo itself, so ghosts drawn after will
    // appear in front. We use BlendMode.screen so they add light rather
    // than occlude.
    if (config.logoTrailIntensity > 0.0 && _logoTexture != null) {
      _renderTrail(canvas);
    }
  }

  // ── Trail rendering ────────────────────────────────────────────────────────

  void _renderTrail(ui.Canvas canvas) {
    final slices = config.logoTrailSlices.clamp(2, 32);
    final intensity = config.logoTrailIntensity.clamp(0.0, 1.0);
    // Request one extra so we can skip i=0 (current position = live logo)
    final positions = game.getTrailPositions(slices + 1);
    if (positions.length < 2) return;

    final logoTex = _logoTexture!;
    final texW = logoTex.width.toDouble();
    final texH = logoTex.height.toDouble();
    final w = size.x;
    final h = size.y;

    // Logo render size MUST match shader logic in steal.frag:
    // shader base height is 110px.
    final basePulse = _beatPulse * 0.08;
    final pulseScale =
        (1.0 + game.currentEnergy.bass * 0.2 * config.pulseIntensity);
    final logoRenderSize = (config.logoScale + basePulse) * 110.0 * pulseScale;

    // Use palette color desaturated — but keep it bright enough to see
    final baseColor =
        _currentColors.isNotEmpty ? _currentColors[0] : const Color(0xFFFFFFFF);
    final hsl = HSLColor.fromColor(baseColor);
    final ghostTint = hsl
        .withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.85).clamp(0.2, 1.0))
        .toColor();

    final srcRect = ui.Rect.fromLTWH(0, 0, texW, texH);

    // Start from i=1 — i=0 is the current frame position (live logo)
    for (int i = 1; i <= slices; i++) {
      if (i >= positions.length) break;

      // t: 0.0 = newest ghost (i=1), 1.0 = oldest ghost (i=slices)
      final t = (i - 1) / (slices - 1).toDouble();
      // Quadratic fade — strong at newest, invisible at oldest
      final opacity = intensity * (1.0 - t) * (1.0 - t) * 0.75;
      if (opacity < 0.01) continue;

      // Dynamic scale reduction toward older slices
      // We apply the initialScale as the starting size (1.0 = native logo size)
      final scale = 1.0 - t * config.logoTrailScale.clamp(0.0, 0.9);
      final renderSize = logoRenderSize * config.logoTrailInitialScale * scale;

      final pos = positions[i];
      final cx = pos.dx * w;
      final cy = pos.dy * h;

      final dst = ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: renderSize,
        height: renderSize * (texH / texW),
      );

      // Screen blend — adds light, works well on dark backgrounds
      final paint = ui.Paint()
        ..blendMode = ui.BlendMode.screen
        ..colorFilter = ui.ColorFilter.mode(
          ghostTint.withValues(alpha: opacity),
          ui.BlendMode.modulate,
        )
        ..filterQuality =
            (config.performanceLevel >= 2 && !config.logoAntiAlias)
                ? ui.FilterQuality.medium
                : ui.FilterQuality.high;

      // Only blur the 2 newest slices
      final shouldBlur = i <= 2 && config.blurAmount > 0.0;

      if (shouldBlur) {
        final sigma = config.blurAmount * 3.0 * (1.0 - t);
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
    // logoScale(7) blurAmount(8) flatColor(9) antiAlias(10) performanceLevel(11)
    // logoPosX(12) logoPosY(13)
    // bass(14) mid(15) treble(16) overall(17)
    // color1(18-20) color2(21-23) color3(24-26) color4(27-29)
    _shader!.setFloat(idx++, config.flowSpeed.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, 0.0); // filmGrain hardcoded off
    _shader!.setFloat(idx++, config.pulseIntensity.clamp(0.0, 5.0));
    _shader!.setFloat(idx++, config.heatDrift.clamp(0.0, 5.0));
    // Apply beat pulse: up to 8% scale boost on beat detection
    final beatBoost = _beatPulse * 0.08;
    _shader!.setFloat(idx++, (config.logoScale + beatBoost).clamp(0.05, 1.1));
    _shader!.setFloat(idx++, config.blurAmount.clamp(0.0, 1.0));
    _shader!.setFloat(idx++, config.flatColor ? 1.0 : 0.0);
    _shader!.setFloat(idx++, config.logoAntiAlias ? 1.0 : 0.0); // uAntiAlias
    _shader!.setFloat(
        idx++, config.performanceLevel.toDouble()); // uPerformanceLevel
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
