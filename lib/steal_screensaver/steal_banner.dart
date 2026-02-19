import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders a circular rotating text banner that orbits the Steal Your Face logo.
///
/// The circle center tracks the same Lissajous path as the shader logo so the
/// text wraps tightly around it as it drifts around the screen.
///
/// Call [updateBanner] whenever track/show metadata or visibility changes.
class StealBanner extends Component with HasGameReference<StealGame> {
  // ── Tuning constants ───────────────────────────────────────────────────────
  static const double _rotationSpeed = 0.04; // rad/sec — slow, meditative
  static const double _radiusRatio = 0.13; // tight wrap around logo
  static const double _fontSize = 11.0; // smaller text
  static const double _fadeSpeed = 0.6; // opacity units per second
  static const int _minArcChars = 28; // floor to prevent clumping
  static const double _letterSpacingBoost = 1.4;

  // ── State ──────────────────────────────────────────────────────────────────
  String _text = '';
  Color _color = Colors.white;
  Color _currentColor = Colors.white; // lerps toward _color each frame
  bool _visible = false;

  double _rotationAngle = 0.0;
  double _opacity = 0.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  void updateBanner(String text, Color color, {bool showBanner = true}) {
    _text = text;
    _color = color;
    // Snap on first assignment so there's no lerp-from-white on init
    if (_currentColor == Colors.white && _opacity == 0.0) {
      _currentColor = color;
    }
    _visible = showBanner && text.isNotEmpty;
  }

  // ── Flame lifecycle ────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    // Lerp color toward target — matches StealBackground crossfade feel
    _currentColor = Color.lerp(_currentColor, _color, 0.025)!;

    if (_visible) {
      _rotationAngle += _rotationSpeed * dt;
      if (_rotationAngle > 2 * pi) _rotationAngle -= 2 * pi;
      _opacity = (_opacity + _fadeSpeed * dt).clamp(0.0, 1.0);
    } else {
      _opacity = (_opacity - _fadeSpeed * dt).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01 || _text.isEmpty) return;

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) return;

    // ── Mirror the shader's logo Lissajous path ────────────────────────────
    // shader: pos = vec2(
    //   0.5 + 0.25*sin(t*1.3) + 0.1*sin(t*2.9),
    //   0.5 + 0.25*cos(t*1.7) + 0.1*cos(t*3.1)
    // )
    // where t = time * flowSpeed * 0.5
    final t = game.time * game.config.flowSpeed.clamp(0.0, 2.0) * 0.5;
    final px = 0.5 + 0.25 * sin(t * 1.3) + 0.1 * sin(t * 2.9);
    final py = 0.5 + 0.25 * cos(t * 1.7) + 0.1 * cos(t * 3.1);

    final center = Offset(px * w, py * h);
    final radius = min(w, h) * _radiusRatio;

    _drawCircularText(canvas, _text, center, radius);
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  void _drawCircularText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
  ) {
    final chars = text.characters.toList();
    if (chars.isEmpty) return;

    final arcCount = max(chars.length, _minArcChars);
    final anglePerSlot = (2 * pi) / arcCount;
    final startAngle = _rotationAngle - pi / 2;

    for (int i = 0; i < chars.length; i++) {
      final charAngle = startAngle + (i * anglePerSlot * _letterSpacingBoost);

      final x = center.dx + radius * cos(charAngle);
      final y = center.dy + radius * sin(charAngle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(charAngle + pi / 2);

      final painter = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: _currentColor.withValues(alpha: _opacity * 0.9),
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: _opacity * 0.7),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(-painter.width / 2, -painter.height / 2),
      );

      canvas.restore();
    }
  }
}
