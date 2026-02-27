import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:shakedown/visualizer/audio_reactor.dart';

/// Audio reactivity graph with two display modes:
/// - **corner**: 8-bar EQ from FFT bands, anchored bottom-left.
/// - **circular**: 8-band radial EQ centered on the logo.
class StealGraph extends Component with HasGameReference {
  AudioEnergy energy = const AudioEnergy.zero();
  bool isVisible = false;

  /// Display mode: 'corner', 'circular', or 'off'.
  String graphMode = 'off';

  /// Number of FFT bands rendered in both modes.
  static const int _bandCount = 8;

  // ── Corner Graph Configuration ──────────────────────────────────────────
  static const double _barWidth = 8.0;
  static const double _barGap = 4.0;
  static const double _maxBarHeight = 80.0;
  static const double _bottomPadding = 48.0;
  static const double _leftPadding = 48.0;
  static const double _cornerRadius = 3.0;

  // ── Circular Graph Configuration ────────────────────────────────────────
  static const double _circRadius = 60.0;
  static const double _circBarWidth = 6.0;
  static const double _circMaxBarHeight = 40.0;

  // ── Smoothing factors for visual fluidity ───────────────────────────────
  static const double _riseSmoothing = 15.0; // Fast rise
  static const double _fallSmoothing = 5.0; // Slower fall

  // Current smoothed heights for corner bars (8 FFT bands)
  final List<double> _cornerHeights = List.filled(_bandCount, 0.0);

  // Current smoothed heights for circular bars (8 FFT bands)
  final List<double> _circularHeights = List.filled(_bandCount, 0.0);

  final Paint _barPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

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

  /// Smooth the 8-band FFT data for corner graph rendering.
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

  /// Render 8-bar EQ anchored bottom-left using FFT band data.
  void _renderCorner(Canvas canvas) {
    final startY = game.size.y - _bottomPadding;
    const startX = _leftPadding;

    for (int i = 0; i < _bandCount; i++) {
      final height = _cornerHeights[i].clamp(2.0, _maxBarHeight);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + (i * (_barWidth + _barGap)),
          startY - height,
          _barWidth,
          height,
        ),
        const Radius.circular(_cornerRadius),
      );
      canvas.drawRRect(rect, _barPaint);
    }
  }

  /// Render 8-band radial EQ centered on the screen.
  void _renderCircular(Canvas canvas) {
    final cx = game.size.x / 2;
    final cy = game.size.y / 2;

    for (int i = 0; i < _bandCount; i++) {
      final angle = (i / _bandCount) * 2 * pi - (pi / 2); // Start from top
      final barHeight = _circularHeights[i].clamp(2.0, _circMaxBarHeight);

      // Inner and outer radii for the bar
      const innerR = _circRadius;
      final outerR = _circRadius + barHeight;

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
