import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Renders a circular rotating text banner around the Steal Your Face logo.
///
/// Text is drawn character-by-character around a circle whose center is the
/// screen centre. The banner fades in when visible and fades out when hidden.
///
/// Call [updateBanner] whenever track/show metadata or visibility changes.
class StealBanner extends Component {
  // ── Tuning constants ───────────────────────────────────────────────────────
  static const double _rotationSpeed = 0.05; // radians per second
  static const double _radiusRatio = 0.42; // fraction of min screen dimension
  static const double _fontSize = 17.0;
  static const double _fadeSpeed = 0.6; // opacity units per second
  static const int _minArcChars =
      28; // min arc spread (prevents clumping on short text)
  static const double _letterSpacingBoost =
      1.4; // spread chars slightly wider than natural

  // ── State ──────────────────────────────────────────────────────────────────
  String _text = '';
  Color _color = Colors.white;
  bool _visible = false;

  double _rotationAngle = 0.0;
  double _opacity = 0.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Update text and color. Visibility is derived from [showBanner] and
  /// whether [text] is non-empty — no need for a separate visible flag.
  ///
  /// [text]       — composed show/track string e.g. "12/31/78 • Winterland • Dark Star"
  /// [color]      — first color of the current palette
  /// [showBanner] — maps to the user's Show Track Info toggle
  void updateBanner(String text, Color color, {bool showBanner = true}) {
    _text = text;
    _color = color;
    _visible = showBanner && text.isNotEmpty;
  }

  // ── Flame lifecycle ────────────────────────────────────────────────────────

  @override
  void update(double dt) {
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

    // Use the game's viewport size via the canvas transform.
    // We pull size from the parent FlameGame via findGame().
    final game = findGame();
    if (game == null) return;

    final w = game.size.x;
    final h = game.size.y;
    final center = Offset(w / 2, h / 2);
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

    // Spread characters evenly. Use _minArcChars as floor so short strings
    // don't clump at the top.
    final arcCount = max(chars.length, _minArcChars);
    final anglePerSlot = (2 * pi) / arcCount;

    // Start at top of circle (−π/2) offset by current rotation
    final startAngle = _rotationAngle - pi / 2;

    for (int i = 0; i < chars.length; i++) {
      final charAngle = startAngle + (i * anglePerSlot * _letterSpacingBoost);

      final x = center.dx + radius * cos(charAngle);
      final y = center.dy + radius * sin(charAngle);

      canvas.save();
      canvas.translate(x, y);
      // Rotate so the character baseline is tangent to the circle
      canvas.rotate(charAngle + pi / 2);

      final painter = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: _color.withValues(alpha: _opacity * 0.9),
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: _opacity * 0.6),
                blurRadius: 4,
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
