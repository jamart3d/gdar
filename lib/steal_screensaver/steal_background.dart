import 'dart:async';
import 'dart:math';
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

  // Always maintain exactly 4 colors for the shader.
  // Shorter palettes pad with their last color.
  static const int _colorCount = 4;

  List<Color> _currentColors = [];
  List<Color> _targetColors = [];

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
      _currentColors[i] = Color.lerp(
        _currentColors[i],
        _targetColors[i],
        _colorLerpSpeed,
      )!;
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
