import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders three circular rotating text rings that orbit the Steal Your Face logo.
///
/// Outer ring:  venue        — clockwise, fastest (largest radius)
/// Middle ring: track title  — clockwise, medium
/// Inner ring:  date         — clockwise, slowest (smallest radius)
///
/// All rings rotate clockwise. Speed scales with radius so apparent letter
/// velocity is consistent across all three rings.
///
/// Letter angle is derived directly from font size / radius so letters are
/// always pixel-accurate — never spread around the circumference.
class StealBanner extends Component with HasGameReference<StealGame> {
  // ── Rotation ───────────────────────────────────────────────────────────────
  static const double _baseRotationSpeed = 0.0006;

  // ── Base inner radius ──────────────────────────────────────────────────────
  static const double _baseInnerRadiusRatio = 0.110;

  // ── Minimum ring clearance at gap=0 ───────────────────────────────────────
  // Just enough so letters on adjacent rings don't clip (~19px on 1080p TV).
  static const double _minRingClearance = 0.018;

  // ── Font & letter spacing ──────────────────────────────────────────────────
  static const double _fontSize = 11.0;
  // 1.0 = letters touching, 1.08 = small natural gap readable at TV distance
  static const double _letterSpacingBoost = 1.08;

  // ── Fade ───────────────────────────────────────────────────────────────────
  static const double _fadeSpeed = 0.6;
  static const double _ringFadeSpeed = 1.2;

  // ── Flicker ────────────────────────────────────────────────────────────────
  static const double _flickerLerpSpeed = 18.0;

  // ── Per-ring state ─────────────────────────────────────────────────────────
  String _outerCurrent = '';
  String _outerPending = '';
  double _outerOpacity = 0.0;
  bool _outerFadingOut = false;
  double _outerAngle = 0.0;

  String _middleCurrent = '';
  String _middlePending = '';
  double _middleOpacity = 0.0;
  bool _middleFadingOut = false;
  double _middleAngle = 0.0;

  String _innerCurrent = '';
  String _innerPending = '';
  double _innerOpacity = 0.0;
  bool _innerFadingOut = false;
  double _innerAngle = 0.0;

  // ── Shared ─────────────────────────────────────────────────────────────────
  Color _color = Colors.white;
  Color _currentColor = Colors.white;
  bool _visible = false;
  double _opacity = 0.0;

  // ── Flicker ────────────────────────────────────────────────────────────────
  final _rng = Random();
  double _flickerValue = 1.0;
  double _flickerTarget = 1.0;
  double _flickerTimer = 0.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  void updateBanner(
    String trackTitle,
    Color color, {
    bool showBanner = true,
    String venue = '',
    String date = '',
  }) {
    _color = color;
    _visible = showBanner &&
        (trackTitle.isNotEmpty || venue.isNotEmpty || date.isNotEmpty);

    if (_currentColor == Colors.white && _opacity == 0.0) {
      _currentColor = color;
    }

    _queueRingUpdate(
      newText: venue,
      current: _outerCurrent,
      opacity: _outerOpacity,
      setCurrent: (v) => _outerCurrent = v,
      setPending: (v) => _outerPending = v,
      setFadingOut: (v) => _outerFadingOut = v,
    );
    _queueRingUpdate(
      newText: trackTitle,
      current: _middleCurrent,
      opacity: _middleOpacity,
      setCurrent: (v) => _middleCurrent = v,
      setPending: (v) => _middlePending = v,
      setFadingOut: (v) => _middleFadingOut = v,
    );
    _queueRingUpdate(
      newText: date,
      current: _innerCurrent,
      opacity: _innerOpacity,
      setCurrent: (v) => _innerCurrent = v,
      setPending: (v) => _innerPending = v,
      setFadingOut: (v) => _innerFadingOut = v,
    );
  }

  void _queueRingUpdate({
    required String newText,
    required String current,
    required double opacity,
    required void Function(String) setCurrent,
    required void Function(String) setPending,
    required void Function(bool) setFadingOut,
  }) {
    if (newText == current) {
      return;
    }
    if (opacity <= 0.05 || current.isEmpty) {
      setCurrent(newText);
      setFadingOut(false);
    } else {
      setPending(newText);
      setFadingOut(true);
    }
  }

  // ── Flame update ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    _currentColor = Color.lerp(_currentColor, _color, 0.025)!;

    final StealConfig config = game.config;
    final minDim = min(game.size.x, game.size.y);
    final innerR = _innerRadius(minDim, config);
    final middleR = _middleRadius(minDim, config, innerR);
    final outerR = _outerRadius(minDim, config, middleR);

    if (_visible) {
      _innerAngle += _baseRotationSpeed * innerR * dt;
      _middleAngle += _baseRotationSpeed * middleR * dt;
      _outerAngle += _baseRotationSpeed * outerR * dt;
      if (_innerAngle > 2 * pi) {
        _innerAngle -= 2 * pi;
      }
      if (_middleAngle > 2 * pi) {
        _middleAngle -= 2 * pi;
      }
      if (_outerAngle > 2 * pi) {
        _outerAngle -= 2 * pi;
      }
      _opacity = (_opacity + _fadeSpeed * dt).clamp(0.0, 1.0);
    } else {
      _opacity = (_opacity - _fadeSpeed * dt).clamp(0.0, 1.0);
    }

    _tickFade(
        dt,
        _outerFadingOut,
        _outerOpacity,
        _outerPending,
        (v) => _outerOpacity = v,
        (v) => _outerCurrent = v,
        (v) => _outerPending = v,
        (v) => _outerFadingOut = v);
    _tickFade(
        dt,
        _middleFadingOut,
        _middleOpacity,
        _middlePending,
        (v) => _middleOpacity = v,
        (v) => _middleCurrent = v,
        (v) => _middlePending = v,
        (v) => _middleFadingOut = v);
    _tickFade(
        dt,
        _innerFadingOut,
        _innerOpacity,
        _innerPending,
        (v) => _innerOpacity = v,
        (v) => _innerCurrent = v,
        (v) => _innerPending = v,
        (v) => _innerFadingOut = v);

    _tickFlicker(dt);
  }

  void _tickFade(
    double dt,
    bool fadingOut,
    double opacity,
    String pending,
    void Function(double) setOpacity,
    void Function(String) setCurrent,
    void Function(String) setPending,
    void Function(bool) setFadingOut,
  ) {
    if (fadingOut) {
      final next = (opacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      setOpacity(next);
      if (next <= 0.0) {
        setCurrent(pending);
        setPending('');
        setFadingOut(false);
      }
    } else {
      if (_visible) {
        setOpacity((opacity + _ringFadeSpeed * dt).clamp(0.0, 1.0));
      } else {
        setOpacity((opacity - _ringFadeSpeed * dt).clamp(0.0, 1.0));
      }
    }
  }

  void _tickFlicker(double dt) {
    final strength = game.config.bannerFlicker.clamp(0.0, 1.0);
    if (strength <= 0.0) {
      _flickerValue = (_flickerValue + _flickerLerpSpeed * dt).clamp(0.0, 1.0);
      return;
    }
    _flickerValue += (_flickerTarget - _flickerValue) * _flickerLerpSpeed * dt;
    _flickerValue = _flickerValue.clamp(0.0, 1.0);
    _flickerTimer -= dt;
    if (_flickerTimer <= 0.0) {
      final minBrightness = 1.0 - strength * 0.85;
      _flickerTarget =
          minBrightness + _rng.nextDouble() * (1.0 - minBrightness);
      final minInterval = ui.lerpDouble(0.3, 0.04, strength)!;
      final maxInterval = ui.lerpDouble(1.2, 0.15, strength)!;
      _flickerTimer =
          minInterval + _rng.nextDouble() * (maxInterval - minInterval);
    }
  }

  // ── Radius helpers ─────────────────────────────────────────────────────────

  double _innerRadius(double minDim, StealConfig config) =>
      minDim * _baseInnerRadiusRatio * config.innerRingScale.clamp(0.5, 2.0);

  double _middleRadius(double minDim, StealConfig config, double innerR) {
    // At gap=0: just enough clearance for letters not to clip.
    // gap 0→1 adds up to ~8% of minDim of additional separation.
    final gap = config.innerToMiddleGap.clamp(0.0, 1.0);
    return innerR + minDim * (_minRingClearance + gap * 0.08);
  }

  double _outerRadius(double minDim, StealConfig config, double middleR) {
    final gap = config.middleToOuterGap.clamp(0.0, 1.0);
    return middleR + minDim * (_minRingClearance + gap * 0.08);
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) {
      return;
    }

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) {
      return;
    }

    final StealConfig config = game.config;
    final drift = config.orbitDrift.clamp(0.0, 2.0);
    final t = game.time * config.flowSpeed.clamp(0.0, 2.0) * 0.5;

    final px = 0.5 + 0.25 * drift * sin(t * 1.3) + 0.1 * drift * sin(t * 2.9);
    final py = 0.5 + 0.25 * drift * cos(t * 1.7) + 0.1 * drift * cos(t * 3.1);
    final center = Offset(px * w, py * h);

    final minDim = min(w, h);
    final innerR = _innerRadius(minDim, config);
    final middleR = _middleRadius(minDim, config, innerR);
    final outerR = _outerRadius(minDim, config, middleR);

    final glowEnabled = config.bannerGlow;
    final flicker = _flickerValue;

    if (_outerCurrent.isNotEmpty && _outerOpacity > 0.01) {
      _drawRing(canvas, _outerCurrent, center, outerR, _outerAngle,
          _opacity * _outerOpacity * flicker, glowEnabled);
    }
    if (_middleCurrent.isNotEmpty && _middleOpacity > 0.01) {
      _drawRing(canvas, _middleCurrent, center, middleR, _middleAngle,
          _opacity * _middleOpacity * flicker, glowEnabled);
    }
    if (_innerCurrent.isNotEmpty && _innerOpacity > 0.01) {
      _drawRing(canvas, _innerCurrent, center, innerR, _innerAngle,
          _opacity * _innerOpacity * flicker, glowEnabled);
    }
  }

  void _drawRing(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double startAngle,
    double effectiveOpacity,
    bool glowEnabled,
  ) {
    final chars = text.characters.toList();
    if (chars.isEmpty) {
      return;
    }

    // Pixel-accurate letter placement: derive angle from font size / radius.
    // This means letters are always exactly as close as the font dictates,
    // regardless of text length or ring size — never spread around the circle.
    final charAngle = (_fontSize * _letterSpacingBoost) / radius;

    // Center the arc at the rotation origin (top of ring at startAngle)
    final arcSpan = charAngle * (chars.length - 1);
    final centeredStart = startAngle - pi / 2 - arcSpan / 2;

    final hsl = HSLColor.fromColor(_currentColor);
    final coreColor = hsl.withSaturation(0.3).withLightness(0.95).toColor();
    final bloomColor = hsl.withSaturation(1.0).withLightness(0.6).toColor();
    final glowColor = hsl.withSaturation(1.0).withLightness(0.5).toColor();

    for (int i = 0; i < chars.length; i++) {
      final angle = centeredStart + i * charAngle;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 2);

      if (glowEnabled) {
        _paintChar(canvas, chars[i],
            color: glowColor.withValues(alpha: effectiveOpacity * 0.45),
            blurRadius: 10.0);
        _paintChar(canvas, chars[i],
            color: bloomColor.withValues(alpha: effectiveOpacity * 0.75),
            blurRadius: 3.5);
        _paintChar(canvas, chars[i],
            color: coreColor.withValues(alpha: effectiveOpacity * 0.95),
            blurRadius: 0.0);
      } else {
        _paintChar(canvas, chars[i],
            color: _currentColor.withValues(alpha: effectiveOpacity * 0.9),
            blurRadius: 0.0,
            withDropShadow: true,
            dropShadowOpacity: effectiveOpacity);
      }

      canvas.restore();
    }
  }

  void _paintChar(
    Canvas canvas,
    String char, {
    required Color color,
    required double blurRadius,
    bool withDropShadow = false,
    double dropShadowOpacity = 1.0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          shadows: withDropShadow
              ? [
                  Shadow(
                    color:
                        Colors.black.withValues(alpha: dropShadowOpacity * 0.7),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final offset = Offset(-painter.width / 2, -painter.height / 2);

    if (blurRadius > 0.0) {
      canvas.saveLayer(
        null,
        Paint()
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurRadius),
      );
      painter.paint(canvas, offset);
      canvas.restore();
    } else {
      painter.paint(canvas, offset);
    }
  }
}
