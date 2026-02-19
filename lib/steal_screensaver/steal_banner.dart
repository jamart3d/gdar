import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders two circular rotating text rings that orbit the Steal Your Face logo.
///
/// Outer ring: venue + date, rotating clockwise.
/// Inner ring: track title, rotating counter-clockwise at a slower speed.
///
/// Both rings fade through black when their content changes.
class StealBanner extends Component with HasGameReference<StealGame> {
  // ── Tuning constants ───────────────────────────────────────────────────────
  static const double _outerRotationSpeed = 0.04;
  static const double _innerRotationSpeed = 0.028;
  static const double _outerRadiusRatio = 0.155;
  static const double _innerRadiusRatio = 0.105;
  static const double _fontSize = 11.0;
  static const double _fadeSpeed = 0.6;
  static const double _ringFadeSpeed = 1.2;
  static const int _minArcChars = 28;
  static const double _letterSpacingBoost = 1.4;

  // ── Outer ring state (venue · date) ───────────────────────────────────────
  String _outerCurrent = '';
  String _outerPending = '';
  double _outerOpacity = 0.0;
  bool _outerFadingOut = false;

  // ── Inner ring state (track title) ────────────────────────────────────────
  String _trackCurrent = '';
  String _trackPending = '';
  double _trackOpacity = 0.0;
  bool _trackFadingOut = false;

  // ── Shared ─────────────────────────────────────────────────────────────────
  Color _color = Colors.white;
  Color _currentColor = Colors.white;
  bool _visible = false;

  double _outerAngle = 0.0;
  double _innerAngle = 0.0;
  double _opacity = 0.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  void updateBanner(
    String text,
    Color color, {
    bool showBanner = true,
    String venue = '',
    String date = '',
  }) {
    _color = color;
    _visible = showBanner && text.isNotEmpty;

    if (_currentColor == Colors.white && _opacity == 0.0) {
      _currentColor = color;
    }

    // Inner ring: track title
    if (text != _trackCurrent) {
      if (_trackOpacity <= 0.05 || _trackCurrent.isEmpty) {
        _trackCurrent = text;
        _trackFadingOut = false;
      } else {
        _trackPending = text;
        _trackFadingOut = true;
      }
    }

    // Outer ring: venue · date
    final newOuter = _buildOuterText(venue, date);
    if (newOuter != _outerCurrent) {
      if (_outerOpacity <= 0.05 || _outerCurrent.isEmpty) {
        _outerCurrent = newOuter;
        _outerFadingOut = false;
      } else {
        _outerPending = newOuter;
        _outerFadingOut = true;
      }
    }
  }

  // ── Flame lifecycle ────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    _currentColor = Color.lerp(_currentColor, _color, 0.025)!;

    if (_visible) {
      _outerAngle += _outerRotationSpeed * dt;
      if (_outerAngle > 2 * pi) _outerAngle -= 2 * pi;

      _innerAngle -= _innerRotationSpeed * dt;
      if (_innerAngle < -2 * pi) _innerAngle += 2 * pi;

      _opacity = (_opacity + _fadeSpeed * dt).clamp(0.0, 1.0);
    } else {
      _opacity = (_opacity - _fadeSpeed * dt).clamp(0.0, 1.0);
    }

    // Inner ring fade-through state machine
    if (_trackFadingOut) {
      _trackOpacity = (_trackOpacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      if (_trackOpacity <= 0.0) {
        _trackCurrent = _trackPending;
        _trackPending = '';
        _trackFadingOut = false;
      }
    } else {
      if (_trackCurrent.isNotEmpty && _visible) {
        _trackOpacity = (_trackOpacity + _ringFadeSpeed * dt).clamp(0.0, 1.0);
      } else if (!_visible) {
        _trackOpacity = (_trackOpacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      }
    }

    // Outer ring fade-through state machine
    if (_outerFadingOut) {
      _outerOpacity = (_outerOpacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      if (_outerOpacity <= 0.0) {
        _outerCurrent = _outerPending;
        _outerPending = '';
        _outerFadingOut = false;
      }
    } else {
      if (_outerCurrent.isNotEmpty && _visible) {
        _outerOpacity = (_outerOpacity + _ringFadeSpeed * dt).clamp(0.0, 1.0);
      } else if (!_visible) {
        _outerOpacity = (_outerOpacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) return;

    final t = game.time * game.config.flowSpeed.clamp(0.0, 2.0) * 0.5;
    final px = 0.5 + 0.25 * sin(t * 1.3) + 0.1 * sin(t * 2.9);
    final py = 0.5 + 0.25 * cos(t * 1.7) + 0.1 * cos(t * 3.1);

    final center = Offset(px * w, py * h);
    final outerRadius = min(w, h) * _outerRadiusRatio;
    final innerRadius = min(w, h) * _innerRadiusRatio;

    // Outer ring: venue · date (clockwise)
    if (_outerCurrent.isNotEmpty && _outerOpacity > 0.01) {
      _drawCircularText(
        canvas,
        _outerCurrent,
        center,
        outerRadius,
        _outerAngle,
        effectiveOpacity: _opacity * _outerOpacity,
        clockwise: true,
      );
    }

    // Inner ring: track title (counter-clockwise)
    if (_trackCurrent.isNotEmpty && _trackOpacity > 0.01) {
      _drawCircularText(
        canvas,
        _trackCurrent,
        center,
        innerRadius,
        _innerAngle,
        effectiveOpacity: _opacity * _trackOpacity,
        clockwise: false,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _buildOuterText(String venue, String date) {
    if (venue.isEmpty && date.isEmpty) return '';
    if (venue.isEmpty) return date;
    if (date.isEmpty) return venue;
    return '$venue  ·  $date';
  }

  void _drawCircularText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double startRotation, {
    required double effectiveOpacity,
    required bool clockwise,
  }) {
    final chars = text.characters.toList();
    if (chars.isEmpty) return;

    final arcCount = max(chars.length, _minArcChars);
    final anglePerSlot = (2 * pi) / arcCount;
    final startAngle = startRotation - pi / 2;

    for (int i = 0; i < chars.length; i++) {
      final slotAngle = clockwise
          ? startAngle + (i * anglePerSlot * _letterSpacingBoost)
          : startAngle - (i * anglePerSlot * _letterSpacingBoost);

      final x = center.dx + radius * cos(slotAngle);
      final y = center.dy + radius * sin(slotAngle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(clockwise ? slotAngle + pi / 2 : slotAngle - pi / 2);

      final painter = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: _currentColor.withValues(alpha: effectiveOpacity * 0.9),
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: effectiveOpacity * 0.7),
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
