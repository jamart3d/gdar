import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, TextSpan, TextPainter, TextDirection, FontWeight;
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Audio reactivity graph with two display modes:
/// - **corner**: 8-bar EQ + Beat indicator, anchored bottom-left.
/// - **circular**: 8-band radial EQ centered on the logo.
class StealGraph extends Component with HasGameReference<StealGame> {
  AudioEnergy energy = const AudioEnergy.zero();
  bool isVisible = false;

  /// Display mode: 'corner', 'circular', or 'off'.
  String graphMode = 'off';

  /// Number of FFT bands rendered.
  static const int _bandCount = 8;

  /// Number of bars in corner graph (8 bands + 1 beat indicator).
  static const int _cornerBarCount = 9;

  // ── Corner Graph Configuration ──────────────────────────────────────────
  static const double _barWidth = 8.0;
  static const double _barGap = 4.0;
  static const double _maxBarHeight = 80.0;
  static const double _bottomPadding = 64.0; // Increased for vertical labels
  static const double _leftPadding = 48.0;
  static const double _cornerRadius = 3.0;

  static const List<String> _cornerLabels = [
    'SUB',
    'BASS',
    'LMID',
    'MID',
    'UMID',
    'PRES',
    'BRIL',
    'AIR',
    'BEAT'
  ];

  // ── Circular Graph Configuration ────────────────────────────────────────
  static const double _circBarWidth = 6.0;
  static const double _circMaxBarHeight = 40.0;

  // ── Smoothing factors for visual fluidity ───────────────────────────────
  static const double _riseSmoothing = 15.0; // Fast rise
  static const double _fallSmoothing = 5.0; // Slower fall

  // Current smoothed heights for corner bars (8 FFT bands + 1 Beat)
  final List<double> _cornerHeights = List.filled(_cornerBarCount, 0.0);

  // Current smoothed heights for circular bars (8 FFT bands)
  final List<double> _circularHeights = List.filled(_bandCount, 0.0);

  final Paint _barPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

  final TextPainter _textPainter =
      TextPainter(textDirection: TextDirection.ltr);

  @override
  void update(double dt) {
    super.update(dt);
    if (!isVisible) return;

    if (graphMode == 'corner') {
      _updateCornerHeights(dt);
    } else if (graphMode == 'circular') {
      _updateCircularHeights(dt);
    }
  }

  /// Smooth the 8-band FFT data + Beat for corner graph rendering.
  void _updateCornerHeights(double dt) {
    final bands = energy.bands;
    for (int i = 0; i < _bandCount; i++) {
      final target =
          (i < bands.length ? bands[i] : 0.0).clamp(0.0, 1.0) * _maxBarHeight;
      final current = _cornerHeights[i];
      if (target > current) {
        _cornerHeights[i] += (target - current) * _riseSmoothing * dt;
      } else {
        _cornerHeights[i] += (target - current) * _fallSmoothing * dt;
      }
    }

    // Beat bar (index 8)
    final targetBeat = energy.isBeat ? _maxBarHeight : 0.0;
    final currentBeat = _cornerHeights[_bandCount];
    if (targetBeat > currentBeat) {
      _cornerHeights[_bandCount] = targetBeat; // Instant spike on beat
    } else {
      _cornerHeights[_bandCount] +=
          (targetBeat - currentBeat) * _fallSmoothing * dt;
    }
  }

  /// Smooth the 8-band FFT data for circular graph rendering.
  void _updateCircularHeights(double dt) {
    final bands = energy.bands;
    for (int i = 0; i < _bandCount; i++) {
      final target = (i < bands.length ? bands[i] : 0.0).clamp(0.0, 1.0) *
          _circMaxBarHeight;
      final current = _circularHeights[i];
      if (target > current) {
        _circularHeights[i] += (target - current) * _riseSmoothing * dt;
      } else {
        _circularHeights[i] += (target - current) * _fallSmoothing * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (graphMode == 'corner') {
      _renderCorner(canvas);
    } else if (graphMode == 'circular') {
      _renderCircular(canvas);
    }
  }

  /// Render 8-bar EQ + Beat anchored bottom-left using FFT band data.
  void _renderCorner(Canvas canvas) {
    final startY = game.size.y - _bottomPadding;
    const startX = _leftPadding;

    for (int i = 0; i < _cornerBarCount; i++) {
      final height = _cornerHeights[i].clamp(2.0, _maxBarHeight);
      final centerX = startX + (i * (_barWidth + _barGap)) + (_barWidth / 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + (i * (_barWidth + _barGap)),
          startY - height,
          _barWidth,
          height,
        ),
        const Radius.circular(_cornerRadius),
      );

      // If it's the beat bar, we color it slightly differently
      if (i == _bandCount) {
        canvas.drawRRect(
            rect,
            Paint()
              ..color = (energy.isBeat
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3))
                  .withValues(alpha: 0.8)
              ..style = PaintingStyle.fill);
      } else {
        canvas.drawRRect(rect, _barPaint);
      }

      // Draw vertical label
      canvas.save();
      canvas.translate(centerX, startY + 6.0); // 6px padding below bar
      canvas.rotate(
          -pi / 2); // rotate text to be vertical (reading bottom-to-top)

      _textPainter.text = TextSpan(
        text: _cornerLabels[i],
        style: TextStyle(
          color: i == _bandCount
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.5),
          fontSize: 8,
          fontWeight: i == _bandCount ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 1.0,
          fontFamily: 'Inter',
        ),
      );
      _textPainter.layout();

      // Center vertically on the bar's width, and anchor right edge to the top (which is x=0 in this rotated coordinate space)
      _textPainter.paint(
          canvas, Offset(-_textPainter.width, -_textPainter.height / 2));
      canvas.restore();
    }
  }

  /// Render 8-band radial EQ centered on the logo.
  void _renderCircular(Canvas canvas) {
    // Determine center based on the smoothed logo position instead of screen center
    final logoUV = game.smoothedLogoPos;
    final cx = logoUV.dx * game.size.x;
    final cy = logoUV.dy * game.size.y;

    // Determine minimal rendering dimension (mimics shader logic)
    final minDim = min(game.size.x, game.size.y);
    // Approximate the logo's scaled radius + some padding so the bars start just outside the main body
    final dynamicRadius =
        (game.config.logoScale * minDim * 0.45).clamp(40.0, 300.0);

    for (int i = 0; i < _bandCount; i++) {
      final angle = (i / _bandCount) * 2 * pi - (pi / 2); // Start from top
      final barHeight = _circularHeights[i].clamp(2.0, _circMaxBarHeight);

      // Inner and outer radii for the bar
      final innerR = dynamicRadius;
      final outerR = dynamicRadius + barHeight;

      // Calculate bar center line direction
      final dirX = cos(angle);
      final dirY = sin(angle);

      // Perpendicular direction for bar width
      final perpX = -dirY;
      final perpY = dirX;

      const halfW = _circBarWidth / 2;

      // Four corners of the bar (inner-left, inner-right, outer-right, outer-left)
      final path = Path()
        ..moveTo(cx + dirX * innerR + perpX * halfW,
            cy + dirY * innerR + perpY * halfW)
        ..lineTo(cx + dirX * innerR - perpX * halfW,
            cy + dirY * innerR - perpY * halfW)
        ..lineTo(cx + dirX * outerR - perpX * halfW,
            cy + dirY * outerR - perpY * halfW)
        ..lineTo(cx + dirX * outerR + perpX * halfW,
            cy + dirY * outerR + perpY * halfW)
        ..close();

      canvas.drawPath(path, _barPaint);
    }
  }
}
