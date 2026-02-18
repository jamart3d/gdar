import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders scrolling circular text around the Steal Your Face logo.
class StealBanner extends PositionComponent with HasGameReference<StealGame> {
  String _bannerText = '';
  Color _paletteColor = Colors.white;
  double _opacity = 0.0;
  double _rotationAngle = 0.0;
  bool _fadingIn = false;

  static const double _rotationSpeed = 0.08; // radians per second
  static const double _radiusMultiplier = 0.38; // fraction of screen min dim
  static const double _fontSize = 18.0;
  static const int _minSpacing = 20; // min arc slots if text is short
  static const double _fadeDuration = 1.5; // seconds to fade in/out

  StealBanner();

  /// Current banner text — read by StealGame to pass color updates.
  String get currentText => _bannerText;

  void updateBanner(String text, Color paletteColor) {
    final changed = text != _bannerText;
    _bannerText = text;
    _paletteColor = paletteColor;
    if (changed && text.isNotEmpty) {
      _fadingIn = true;
    }
    if (text.isEmpty) {
      _fadingIn = false;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotationAngle += _rotationSpeed * dt;

    // Fade in when text is present, fade out when empty
    if (_bannerText.isNotEmpty && _fadingIn) {
      _opacity = (_opacity + dt / _fadeDuration).clamp(0.0, 1.0);
    } else if (_bannerText.isEmpty) {
      _opacity = (_opacity - dt / _fadeDuration).clamp(0.0, 1.0);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_bannerText.isEmpty || _opacity <= 0.01) return;
    if (size.x <= 10 || size.y <= 10) return;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = min(size.x, size.y) * _radiusMultiplier;

    _drawCircularText(canvas, _bannerText, center, radius);
  }

  void _drawCircularText(
      ui.Canvas canvas, String text, Offset center, double radius) {
    final chars = text.characters.toList();
    if (chars.isEmpty) return;

    final slotCount = max(chars.length, _minSpacing);
    final anglePerChar = (2 * pi) / slotCount;
    final color = _paletteColor.withValues(alpha: _opacity * 0.85);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < chars.length; i++) {
      final charAngle = _rotationAngle + (i * anglePerChar);
      final x = center.dx + radius * cos(charAngle);
      final y = center.dy + radius * sin(charAngle);

      textPainter.text = TextSpan(
        text: chars[i],
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 4,
            ),
          ],
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(charAngle + pi / 2); // tangent to circle
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }
}
