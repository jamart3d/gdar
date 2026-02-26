import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:shakedown/visualizer/audio_reactor.dart';

class StealGraph extends Component with HasGameReference {
  AudioEnergy energy = const AudioEnergy.zero();
  bool isVisible = false;

  // ── Graph Configuration ────────────────────────────────────────────────────
  static const double _barWidth = 10.0;
  static const double _barGap = 6.0;
  static const double _maxBarHeight = 80.0;
  static const double _bottomPadding = 48.0;
  static const double _leftPadding = 48.0;
  static const double _cornerRadius = 4.0;

  // Smoothing factors for visual fluidity
  static const double _riseSmoothing = 15.0; // Fast rise
  static const double _fallSmoothing = 5.0; // Slower fall

  // Current smoothed heights for each bar (Bass, Mid, Treble, Overall)
  final List<double> _currentHeights = [0.0, 0.0, 0.0, 0.0];

  final Paint _barPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isVisible) return;

    // Target heights mapped from 0.0 -> 1.0 energy to 0 -> _maxBarHeight
    // Overall is usually a bit higher on average, so we scale it gently.
    final targetHeights = [
      (energy.bass.clamp(0.0, 1.0) * _maxBarHeight),
      (energy.mid.clamp(0.0, 1.0) * _maxBarHeight),
      (energy.treble.clamp(0.0, 1.0) * _maxBarHeight),
      (energy.overall.clamp(0.0, 1.0) * _maxBarHeight * 0.8),
    ];

    // Interpolate current heights towards target heights
    for (int i = 0; i < 4; i++) {
      final target = targetHeights[i];
      final current = _currentHeights[i];

      if (target > current) {
        _currentHeights[i] += (target - current) * _riseSmoothing * dt;
      } else {
        _currentHeights[i] += (target - current) * _fallSmoothing * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    // We anchor the bottom-left of the entire graph block
    // to the lower-left corner of the screen, accounting for padding.
    // The bars grow UPWARDS.

    // Y-coordinate of the bottom of the bars
    final startY = game.size.y - _bottomPadding;
    const startX = _leftPadding;

    for (int i = 0; i < 4; i++) {
      final height = _currentHeights[i].clamp(2.0, _maxBarHeight);

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
}
