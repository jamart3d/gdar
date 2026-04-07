import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, HSLColor;
import 'package:flutter/services.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:shakedown_core/utils/asset_constants.dart';

class TrailSnapshot {
  final ui.Offset pos;
  final double size;
  final ui.Color color;

  const TrailSnapshot(this.pos, this.size, this.color);

  static TrailSnapshot lerp(TrailSnapshot a, TrailSnapshot b, double t) {
    return TrailSnapshot(
      ui.Offset.lerp(a.pos, b.pos, t)!,
      ui.lerpDouble(a.size, b.size, t) ?? a.size,
      ui.Color.lerp(a.color, b.color, t)!,
    );
  }
}

class StealBackground extends PositionComponent
    with HasGameReference<StealGame> {
  static const double _beatDebugBottomPad = 100.0;
  static const double _beatDebugMaxHeight = 140.0;
  static const double _beatDebugHeaderReserve = 84.0;
  static const double _beatDebugAvoidMargin = 20.0;

  StealConfig config;
  ui.FragmentShader? _shader;
  ui.Image? _logoTexture;
  bool _shaderLoaded = false;

  // Always maintain exactly 4 colors for the shader.
  // Shorter palettes pad with their last color.
  static const int _colorCount = 4;

  List<Color> _currentColors = List.filled(
    _colorCount,
    const Color(0xFF000000),
  );
  List<Color> _targetColors = List.filled(_colorCount, const Color(0xFF000000));

  double _colorLerpSpeed = 0.025;

  // Smoothed logo position in 0-1 UV space.
  // Lerped each frame toward the raw sin/cos target position.
  // Read by StealBanner via game.smoothedLogoPos to keep rings locked to logo.
  Offset _velocity = Offset.zero;
  Offset _smoothedPos = const Offset(0.5, 0.5);
  Offset _renderedLogoPos = const Offset(0.5, 0.5);

  /// Current smoothed logo position (0-1 UV space). Used by StealBanner.
  Offset get smoothedLogoPos => _smoothedPos;

  /// The final exact logo position including audio nudges (for trails).
  Offset get renderedLogoPos => _renderedLogoPos;

  // Random phase offset applied to motion path so each session starts at a
  // different point on the curve and traces a visually distinct path.
  // Randomised once in onLoad, never changes during a session.
  late final double _phaseOffset;

  // Small random frequency nudges so the Lissajous curve shape itself varies
  // slightly each session - prevents the path ever looking identical.
  late final double _freqNudgeX1;
  late final double _freqNudgeY1;
  late final double _freqNudgeX2;
  late final double _freqNudgeY2;

  // Incremental path time so changes in flow speed don't cause position jumps
  double _pathTime = 0.0;

  // -- Trail position ring buffer ---------------------------------------------
  static const int _trailBufferCapacity = 16;
  final List<TrailSnapshot> _trailBuffer = List.filled(
    _trailBufferCapacity,
    const TrailSnapshot(ui.Offset(0.5, 0.5), 110.0, ui.Color(0xFFFFFFFF)),
  );
  int _trailHead = 0;
  int _trailFrameCount = 0;

  StealBackground({required this.config});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Randomise motion path for this session
    final rng = math.Random();
    // Use a smaller frequency GCD (0.2) to extend the loop duration to ~13 minutes
    // while keeping it perfectly closed and continuous.
    _phaseOffset = rng.nextDouble() * 2 * math.pi; // random start on curve
    _freqNudgeX1 = 0.8;
    _freqNudgeY1 = 1.0;
    _freqNudgeX2 = 1.4;
    _freqNudgeY2 = 1.8;

    try {
      await _loadResources();
      final initial = _expandColors(_getPaletteColors(config.palette));
      _currentColors = List.of(initial);
      _targetColors = List.of(initial);

      // Initialize logo to its correct starting position on the path
      // Apply phaseOffset AFTER the speed multiplier so the starting position
      // is truly random across the entire 0-2pi range regardless of flow speed.
      _pathTime = 0.0;
      final t = _pathTime + _phaseOffset;
      final drift = config.orbitDrift.clamp(0.0, 2.0);
      final startX =
          0.5 +
          0.25 * drift * math.sin(t * _freqNudgeX1) +
          0.1 * drift * math.sin(t * _freqNudgeX2);
      final startY =
          0.5 +
          0.25 * drift * math.cos(t * _freqNudgeY1) +
          0.1 * drift * math.cos(t * _freqNudgeY2);
      _smoothedPos = _applyLogoSafeArea(ui.Offset(startX, startY));
      _renderedLogoPos = _smoothedPos;

      final currentBaseColor = _currentColors.isNotEmpty
          ? _currentColors[0]
          : const ui.Color(0xFFFFFFFF);
      final currentSize = (config.logoScale + _sharedBeatPulseBoost) * 110.0;
      final snap = TrailSnapshot(
        _renderedLogoPos,
        currentSize,
        currentBaseColor,
      );
      for (int i = 0; i < _trailBufferCapacity; i++) {
        _trailBuffer[i] = snap;
      }
    } catch (_) {}
  }

  Future<void> _loadResources() async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/shakedown_core/assets/shaders/steal.frag',
    );
    _shader = program.fragmentShader();

    final data = await rootBundle.load(AssetConstants.stealScreensaverImage);
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

  void overrideTargetColors(List<ui.Color> colors, double lerpSpeed) {
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
      // Ensure current is also always length 4 - prevents lerp skip on mismatch
      if (_currentColors.length != _colorCount) {
        _currentColors = _expandColors(_currentColors);
      }
    }
  }

  /// Pads or trims a color list to exactly [_colorCount] entries.
  /// Shorter lists repeat their last color; longer lists are truncated.
  List<ui.Color> _expandColors(List<ui.Color> colors) {
    if (colors.isEmpty) {
      return List.filled(_colorCount, const ui.Color(0xFFFFFFFF));
    }
    final result = <ui.Color>[];
    for (int i = 0; i < _colorCount; i++) {
      result.add(colors[i < colors.length ? i : colors.length - 1]);
    }
    return result;
  }

  ui.Offset _applyLogoSafeArea(ui.Offset rawPos) {
    if (config.audioGraphMode != 'beat_debug' || size.y <= 0 || size.x <= 0) {
      return rawPos;
    }

    final basePulse = _sharedBeatPulseBoost;
    final logoHalfSize =
        ((config.logoScale + basePulse).clamp(0.05, 1.1) * 110.0) / 2.0;
    final panelTopPx =
        size.y -
        _beatDebugBottomPad -
        _beatDebugMaxHeight -
        _beatDebugHeaderReserve;
    final maxCenterYPx = (panelTopPx - logoHalfSize - _beatDebugAvoidMargin)
        .clamp(logoHalfSize, size.y - logoHalfSize);
    final minCenterYPx = logoHalfSize + 12.0;
    final minCenterXPx = logoHalfSize + 12.0;
    final maxCenterXPx = size.x - logoHalfSize - 12.0;

    // In tiny viewports (like live previews), max might fall below min.
    // Bound the maximums so clamp() is always given valid ranges.
    final safeMaxY = math.max(minCenterYPx, maxCenterYPx);
    final safeMaxX = math.max(minCenterXPx, maxCenterXPx);

    return ui.Offset(
      (rawPos.dx * size.x).clamp(minCenterXPx, safeMaxX) / size.x,
      (rawPos.dy * size.y).clamp(minCenterYPx, safeMaxY) / size.y,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Color lerp - time corrected for frame-rate independence
    // _colorLerpSpeed is based on 60fps frame factor
    final colorAlpha = 1.0 - math.pow(1.0 - _colorLerpSpeed, dt * 60);

    for (int i = 0; i < _colorCount; i++) {
      if (_currentColors.length > i && _targetColors.length > i) {
        _currentColors[i] = ui.Color.lerp(
          _currentColors[i],
          _targetColors[i],
          colorAlpha,
        )!;
      }
    }

    // Compute raw logo target position using incremental path time.
    // This prevents instantaneous jumping when the user changes flow speed.
    _pathTime += dt * config.flowSpeed.clamp(0.0, 2.0) * 0.5;

    // Keep angle arguments bounded to avoid floating-point precision drift
    // during very long sessions (which can present as occasional jumps).
    final t = _pathTime + _phaseOffset;
    final drift = config.orbitDrift.clamp(0.0, 2.0);

    final argX1 = _normalizeAngle(t * _freqNudgeX1);
    final argX2 = _normalizeAngle(t * _freqNudgeX2);
    final argY1 = _normalizeAngle(t * _freqNudgeY1);
    final argY2 = _normalizeAngle(t * _freqNudgeY2);

    final rawX =
        0.5 + 0.25 * drift * math.sin(argX1) + 0.1 * drift * math.sin(argX2);
    final rawY =
        0.5 + 0.25 * drift * math.cos(argY1) + 0.1 * drift * math.cos(argY2);
    final safeRawPos = _applyLogoSafeArea(ui.Offset(rawX, rawY));

    // Lerp smoothedPos toward raw pos using time-based decay
    final s = config.translationSmoothing.clamp(0.0, 1.0);
    // Base alpha per frame (approx 60fps).
    // s=0 -> baseAlpha=1 (instant). s=1 -> baseAlpha=0.01 (very slow).
    final baseAlpha = 1.0 - s * 0.99;
    // Time-corrected alpha: 1 - (1 - base)^dt_ratio
    final posAlpha = 1.0 - math.pow(1.0 - baseAlpha, dt * 60);

    final oldPos = _smoothedPos;
    _smoothedPos = ui.Offset(
      _smoothedPos.dx + (safeRawPos.dx - _smoothedPos.dx) * posAlpha,
      _smoothedPos.dy + (safeRawPos.dy - _smoothedPos.dy) * posAlpha,
    );

    // Track smoothed velocity for dynamic trail scaling
    if (dt > 0) {
      final delta = ui.Offset(
        (_smoothedPos.dx - oldPos.dx) * size.x,
        (_smoothedPos.dy - oldPos.dy) * size.y,
      );
      // Smooth the velocity a bit to avoid jitter in slice count
      final instantVelocity = delta.distance / dt;
      final velocityAlpha = 1.0 - math.pow(0.1, dt * 60); // fast smoothing
      _velocity = ui.Offset(
        _velocity.dx + (instantVelocity - _velocity.dx) * velocityAlpha,
        0,
      );
    }

    // Apply audio nudge to get rendered position
    final react =
        !(config.audioGraphMode == 'corner_only') &&
        config.enableAudioReactivity;
    double ebass = 0.0;
    if (react) {
      final sE =
          switch (config.scaleSource) {
            -2 => 0.0,
            -1 => game.currentEnergy.bass,
            _ => game.currentEnergy.bands[config.scaleSource.clamp(0, 7)],
          } *
          config.scaleMultiplier;

      double sineAmp = 0.0;
      if (_effectiveScaleSineEnabled) {
        final double t = DateTime.now().millisecondsSinceEpoch / 1000.0;
        sineAmp =
            math.sin(t * 2.0 * math.pi * _effectiveScaleSineFreq) *
            config.scaleSineAmp;
      }
      ebass = (sE + sineAmp).clamp(0.0, 5.0);
    }

    final emid = react && _useSecondaryLogoAudioMotion
        ? game.currentEnergy.mid.clamp(0.0, 5.0)
        : 0.0;
    final eover = react && _useSecondaryLogoAudioMotion
        ? game.currentEnergy.overall.clamp(0.0, 5.0)
        : 0.0;
    final pulse = config.pulseIntensity.clamp(0.0, 5.0);

    ui.Offset nudge = ui.Offset.zero;
    if (eover > 0.01) {
      nudge = ui.Offset(ebass - 0.5, emid - 0.5) * 0.05 * pulse;
    }

    _renderedLogoPos = _smoothedPos + nudge;
    _tickTrailBuffer();
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
    // the background but are then composited - ghosts sit between background
    // and the live logo which the shader draws on top.
    // Note: shader renders the logo itself, so ghosts drawn after will
    // appear in front. We use BlendMode.screen so they add light rather
    // than occlude.
    if (config.logoTrailIntensity > 0.0 &&
        config.logoScale > 0.0 &&
        _logoTexture != null) {
      _renderTrail(canvas);
    }
  }

  bool get _usesAutocorrLogoScale =>
      config.beatDetectorMode == 'autocorr' &&
      (config.autocorrLogoVariant == 'pulse' ||
          config.autocorrLogoVariant == 'sine' ||
          config.autocorrLogoVariant == 'both');

  bool get _usesAutocorrPulse =>
      !_usesAutocorrLogoScale ||
      config.autocorrLogoVariant == 'pulse' ||
      config.autocorrLogoVariant == 'both';

  bool get _usesAutocorrSine =>
      _usesAutocorrLogoScale &&
      (config.autocorrLogoVariant == 'sine' ||
          config.autocorrLogoVariant == 'both');

  double get _effectiveScaleSineFreq =>
      _usesAutocorrSine && game.currentEnergy.beatBpm != null
      ? (game.currentEnergy.beatBpm! / 60.0).clamp(0.05, 8.0)
      : config.scaleSineFreq;

  bool get _effectiveScaleSineEnabled =>
      config.scaleSineEnabled || _usesAutocorrSine;

  double get _sharedBeatPulseBoost =>
      _usesAutocorrPulse ? game.beatPulse * 0.08 : 0.0;

  bool get _hasExplicitLogoScaleDriver =>
      config.scaleSource != -2 || _effectiveScaleSineEnabled;

  bool get _hasExplicitLogoColorDriver => config.colorSource != -2;

  bool get _useSecondaryLogoAudioMotion =>
      _hasExplicitLogoScaleDriver || _hasExplicitLogoColorDriver;

  // -- Trail rendering --------------------------------------------------------

  List<TrailSnapshot> _getTrailPositions(int count) {
    final interval = (1 + (config.logoTrailLength * 14.5).round()).clamp(1, 30);
    final frac = _trailFrameCount / interval.toDouble();

    final clamped = count.clamp(0, _trailBufferCapacity - 1);
    final result = <TrailSnapshot>[];

    final currentBaseColor = _currentColors.isNotEmpty
        ? _currentColors[0]
        : const ui.Color(0xFFFFFFFF);
    final currentSize = (config.logoScale + _sharedBeatPulseBoost) * 110.0;

    result.add(TrailSnapshot(_renderedLogoPos, currentSize, currentBaseColor));

    if (clamped <= 1) return result;

    for (int i = 1; i < clamped; i++) {
      final findK = i - frac;
      final k = findK.floor();
      final t = findK - k;

      final idx1 =
          ((_trailHead - k) % _trailBufferCapacity + _trailBufferCapacity) %
          _trailBufferCapacity;
      final idx2 =
          ((_trailHead - (k + 1)) % _trailBufferCapacity +
              _trailBufferCapacity) %
          _trailBufferCapacity;

      final p1 = _trailBuffer[idx1];
      final p2 = _trailBuffer[idx2];

      result.add(TrailSnapshot.lerp(p1, p2, t.clamp(0.0, 1.0)));
    }
    return result;
  }

  void _tickTrailBuffer() {
    if (config.logoScale <= 0.0) return;
    final interval = (1 + (config.logoTrailLength * 14.5).round()).clamp(1, 30);
    _trailFrameCount++;
    if (_trailFrameCount >= interval) {
      _trailFrameCount = 0;
      _trailHead = (_trailHead + 1) % _trailBufferCapacity;

      final currentBaseColor = _currentColors.isNotEmpty
          ? _currentColors[0]
          : const ui.Color(0xFFFFFFFF);
      final currentSize = (config.logoScale + _sharedBeatPulseBoost) * 110.0;

      _trailBuffer[_trailHead] = TrailSnapshot(
        _renderedLogoPos,
        currentSize,
        currentBaseColor,
      );
    }
  }

  void _renderTrail(ui.Canvas canvas) {
    int slices = config.logoTrailSlices.clamp(2, 32);

    if (config.logoTrailDynamic) {
      // Dynamic scaling: higher velocity = more slices.
      // Typical high velocity is ~100-200 pixels/sec at flow 0.1
      final v = _velocity.dx;
      // Map 0 -> 200 to 0.0 -> 1.0
      final nv = (v / 200.0).clamp(0.0, 1.0);
      // Min 2 slices, Max is the user setting
      slices = (2 + (nv * (config.logoTrailSlices - 2))).round();
    }

    final intensity = config.logoTrailIntensity.clamp(0.0, 1.0);
    // Request one extra so we can skip i=0 (current position = live logo)
    final snapshots = _getTrailPositions(slices + 1);
    if (snapshots.length < 2) return;

    final logoTex = _logoTexture!;
    final texW = logoTex.width.toDouble();
    final texH = logoTex.height.toDouble();
    final w = size.x;
    final h = size.y;

    final srcRect = ui.Rect.fromLTWH(0, 0, texW, texH);

    // Start from i=1 - i=0 is the current frame position (live logo)
    for (int i = 1; i <= slices; i++) {
      if (i >= snapshots.length) break;

      final snap = snapshots[i];
      // t: 0.0 = newest ghost (i=1), 1.0 = oldest ghost (i=slices)
      final t = (i - 1) / (slices - 1).toDouble();
      // Quadratic fade - strong at newest, invisible at oldest
      final opacity = intensity * (1.0 - t) * (1.0 - t) * 0.75;
      if (opacity < 0.01) continue;

      // Dynamic scale reduction toward older slices
      // We apply the initialScale as the starting size (1.0 = native logo size)
      final scaleToApply = 1.0 - t * config.logoTrailScale.clamp(0.0, 0.9);
      final renderSize =
          snap.size * config.logoTrailInitialScale * scaleToApply;

      final cx = snap.pos.dx * w;
      final cy = snap.pos.dy * h;

      final hsl = HSLColor.fromColor(snap.color);
      final ghostTint = hsl
          .withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
          .withLightness((hsl.lightness * 0.85).clamp(0.2, 1.0))
          .toColor();

      final dst = ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: renderSize,
        height: renderSize * (texH / texW),
      );

      // Screen blend - adds light, works well on dark backgrounds
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
    // Beat boost now respects Pulse Intensity so low-reactivity settings stay calm.
    final beatBoost = config.enableAudioReactivity
        ? _sharedBeatPulseBoost
        : 0.0;
    final effectiveLogoScale = config.logoScale <= 0.0
        ? 0.0
        : (config.logoScale + beatBoost).clamp(0.05, 1.1);
    _shader!.setFloat(idx++, effectiveLogoScale);
    _shader!.setFloat(idx++, config.blurAmount.clamp(0.0, 1.0));
    _shader!.setFloat(idx++, config.flatColor ? 1.0 : 0.0);
    _shader!.setFloat(idx++, config.logoAntiAlias ? 1.0 : 0.0); // uAntiAlias
    _shader!.setFloat(
      idx++,
      config.performanceLevel.toDouble(),
    ); // uPerformanceLevel
    _shader!.setFloat(idx++, _renderedLogoPos.dx); // uLogoPosX
    _shader!.setFloat(idx++, _renderedLogoPos.dy); // uLogoPosY

    final isCornerOnly = config.audioGraphMode == 'corner_only';

    final react = !isCornerOnly && config.enableAudioReactivity;

    // Scale Energy (Slot 14, historically ebass)
    double sE = 0.0;
    if (react) {
      sE = switch (config.scaleSource) {
        -2 => 0.0,
        -1 => energy.bass,
        _ => energy.bands[config.scaleSource.clamp(0, 7)],
      };
      sE *= config.scaleMultiplier;
    }

    if (_effectiveScaleSineEnabled) {
      final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double sine = math.sin(
        time * 2.0 * math.pi * _effectiveScaleSineFreq,
      );
      sE += sine * config.scaleSineAmp;
    }

    _shader!.setFloat(idx++, sE.clamp(0.0, 5.0));

    // Mid Energy (Slot 15, historically emid)
    final midEnergy = react && _useSecondaryLogoAudioMotion
        ? energy.mid.clamp(0.0, 5.0)
        : 0.0;
    _shader!.setFloat(idx++, midEnergy);

    // Color Energy (Slot 16, historically etreble)
    double cE = 0.0;
    if (react) {
      cE = switch (config.colorSource) {
        -2 => 0.0,
        -1 => energy.treble,
        _ => energy.bands[config.colorSource.clamp(0, 7)],
      };
      cE *= config.colorMultiplier;
    }
    _shader!.setFloat(idx++, cE.clamp(0.0, 5.0));

    // Overall Energy (Slot 17)
    final overallEnergy = react && _useSecondaryLogoAudioMotion
        ? energy.overall.clamp(0.0, 5.0)
        : 0.0;
    _shader!.setFloat(idx++, overallEnergy);

    // Always write exactly 4 colors - shader always expects uColor1-uColor4
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

  double _normalizeAngle(double angle) {
    const tau = 2 * math.pi;
    final mod = angle % tau;
    return mod < 0 ? mod + tau : mod;
  }

  List<ui.Color> _getPaletteColors(String name) {
    return StealConfig.palettes[name] ?? StealConfig.palettes.values.first;
  }

  void _renderFallback(ui.Canvas canvas) {
    canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFF000000));
  }
}
