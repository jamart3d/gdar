import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        TextStyle,
        TextSpan,
        TextPainter,
        TextDirection,
        FontWeight,
        HSLColor;
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';

/// Audio reactivity graph with multiple display modes:
/// - corner: 8-bar EQ + Beat indicator, anchored bottom-left.
/// - circular: 8-band radial EQ centered on the logo.
/// - ekg: 150-sample horizontal guitar-tuned EKG line across bottom.
/// - circular_ekg: 150-sample circular guitar-tuned EKG orbiting logo.
class StealGraph extends Component with HasGameReference<StealGame> {
  AudioEnergy energy = const AudioEnergy.zero();
  bool isVisible = false;

  /// Display mode: 'corner', 'circular', 'ekg', 'circular_ekg', or 'off'.
  String graphMode = 'off';

  /// Number of FFT bands rendered.
  static const int _bandCount = 8;

  /// Number of bars in corner graph (8 FFT bands + 1 beat indicator).
  static const int _cornerBarCount = 9;

  // Corner graph layout.
  static const double _barWidth = 8.0;
  static const double _barGap = 4.0;
  static const double _maxBarHeight = 80.0;
  static const double _bottomPadding = 64.0;
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
    'BEAT',
  ];

  // Circular graph layout.
  static const double _circBarWidth = 6.0;
  static const double _circMaxBarHeight = 40.0;

  // EKG layout.
  static const int _ekgSampleCount = 150;
  static const double _ekgMaxHeight = 45.0;
  static const double _ekgRiseSmoothing = 18.0;
  static const double _ekgFallSmoothing = 8.0;

  // Smoothing and visual timing.
  static const double _riseSmoothing = 15.0;
  static const double _fallSmoothing = 5.0;
  static const double _peakHoldDecayPerSec = 22.0;
  static const double _beatFlashDecayPerSec = 5.5;

  // Current smoothed heights for corner bars (8 FFT bands + 1 Beat).
  final List<double> _cornerHeights = List.filled(_cornerBarCount, 0.0);

  // Peak-hold values for corner bars.
  final List<double> _cornerPeakHeights = List.filled(_cornerBarCount, 0.0);

  // Current smoothed heights for circular bars (8 FFT bands).
  final List<double> _circularHeights = List.filled(_bandCount, 0.0);

  // Peak-hold values for circular bars.
  final List<double> _circularPeakHeights = List.filled(_bandCount, 0.0);

  // EKG history buffer (0.0 - 1.0)
  final List<double> _ekgHistory = List.filled(_ekgSampleCount, 0.0);
  double _lastEkgVal = 0.0;

  // Short-lived beat flash factor for HUD accent.
  double _beatFlash = 0.0;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  static const List<Color> _bandColors = [
    Color(0xFF34E7FF),
    Color(0xFF33D1FF),
    Color(0xFF4AF3C6),
    Color(0xFF8BFF91),
    Color(0xFFFFE66D),
    Color(0xFFFFB84D),
    Color(0xFFFF7A66),
    Color(0xFFFF58A8),
    Color(0xFFFFFFFF),
  ];

  bool get _isFast => game.config.performanceLevel >= 2;
  bool get _isBalanced => game.config.performanceLevel == 1;

  double get _glowSigma {
    if (_isFast) return 0.0;
    if (_isBalanced) return 3.0;
    return 6.0;
  }

  Offset _burnInDrift() {
    // Very slow, tiny drift to prevent OLED static-pixel retention.
    // Keep drift inward so corner mode visually stays in the corner.
    final t = game.time;
    final amp = _isFast
        ? 0.7
        : _isBalanced
        ? 1.1
        : 1.6;

    final nx = (sin(t * 0.031) + sin(t * 0.017 + 1.3) * 0.35 + 1.35) / 2.7;
    final ny =
        (cos(t * 0.027 + 0.4) + cos(t * 0.019 + 2.1) * 0.30 + 1.30) / 2.6;

    final x = nx.clamp(0.0, 1.0) * amp; // right only
    final y = -ny.clamp(0.0, 1.0) * amp; // up only
    return Offset(x, y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isVisible) return;

    if (energy.isBeat) {
      _beatFlash = 1.0;
    } else {
      _beatFlash -= _beatFlashDecayPerSec * dt;
      if (_beatFlash < 0.0) _beatFlash = 0.0;
    }

    if (graphMode == 'corner') {
      _updateCornerHeights(dt);
      _updatePeakHolds(_cornerHeights, _cornerPeakHeights, _maxBarHeight, dt);
    } else if (graphMode == 'circular') {
      _updateCircularHeights(dt);
      _updatePeakHolds(
        _circularHeights,
        _circularPeakHeights,
        _circMaxBarHeight,
        dt,
      );
    }

    // Always update EKG buffer if visible and in an EKG mode
    if (graphMode == 'ekg' || graphMode == 'circular_ekg') {
      _updateEkgHistory(dt);
    }
  }

  /// Extracts "guitar" energy from mids (bands 2, 3, 4) and updates the rolling history.
  void _updateEkgHistory(double dt) {
    final bands = energy.bands;
    if (bands.length < 5) return;

    // Isolate guitar range: LowMid + Mid + UpperMid
    final target = (bands[2] + bands[3] + bands[4]) / 3.0;

    // Smoothed rise/fall
    if (target > _lastEkgVal) {
      _lastEkgVal += (target - _lastEkgVal) * _ekgRiseSmoothing * dt;
    } else {
      _lastEkgVal += (target - _lastEkgVal) * _ekgFallSmoothing * dt;
    }

    // Shift history left
    for (int i = 0; i < _ekgSampleCount - 1; i++) {
      _ekgHistory[i] = _ekgHistory[i + 1];
    }
    _ekgHistory[_ekgSampleCount - 1] = _lastEkgVal.clamp(0.0, 1.0);
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

    // Beat bar (index 8).
    final targetBeat = energy.isBeat ? _maxBarHeight : 0.0;
    final currentBeat = _cornerHeights[_bandCount];
    if (targetBeat > currentBeat) {
      _cornerHeights[_bandCount] = targetBeat;
    } else {
      _cornerHeights[_bandCount] +=
          (targetBeat - currentBeat) * _fallSmoothing * dt;
    }
  }

  /// Smooth the 8-band FFT data for circular graph rendering.
  void _updateCircularHeights(double dt) {
    final bands = energy.bands;
    for (int i = 0; i < _bandCount; i++) {
      final target =
          (i < bands.length ? bands[i] : 0.0).clamp(0.0, 1.0) *
          _circMaxBarHeight;
      final current = _circularHeights[i];
      if (target > current) {
        _circularHeights[i] += (target - current) * _riseSmoothing * dt;
      } else {
        _circularHeights[i] += (target - current) * _fallSmoothing * dt;
      }
    }
  }

  void _updatePeakHolds(
    List<double> values,
    List<double> peaks,
    double maxHeight,
    double dt,
  ) {
    for (int i = 0; i < values.length; i++) {
      if (values[i] >= peaks[i]) {
        peaks[i] = values[i];
      } else {
        peaks[i] = max(0.0, peaks[i] - (_peakHoldDecayPerSec * dt));
      }
      if (peaks[i] > maxHeight) peaks[i] = maxHeight;
    }
  }

  Color _bandColor(int index) {
    return _bandColors[index.clamp(0, _bandColors.length - 1)];
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    switch (graphMode) {
      case 'corner':
        _renderCorner(canvas);
      case 'circular':
        _renderCircular(canvas);
      case 'ekg':
        _renderEKG(canvas);
      case 'circular_ekg':
        _renderCircularEKG(canvas);
    }
  }

  /// Render 150-sample horizontal EKG line across the bottom.
  void _renderEKG(Canvas canvas) {
    final drift = _burnInDrift();
    final w = game.size.x;
    final h = game.size.y;
    final centerY = h - _bottomPadding + drift.dy - (_ekgMaxHeight / 2);
    final startX = _leftPadding + drift.dx;
    final availableWidth = w - (_leftPadding * 2);

    final color = const Color(
      0xFF34E7FF,
    ).withValues(alpha: 0.8); // Phosphor Blue

    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      final opacity = (1.0 / (r + 1)) * color.a;
      final verticalOffset = r * spread; // Offset each line slightly
      final beatThick = energy.isBeat ? 0.8 : 0.0;

      final points = <Offset>[];
      for (int i = 0; i < _ekgSampleCount; i++) {
        final x = startX + (i / (_ekgSampleCount - 1)) * availableWidth;
        final y =
            centerY - (_ekgHistory[i] * _ekgMaxHeight) + (verticalOffset * 0.5);
        points.add(Offset(x, y));
      }

      if (r == 0 && _glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = color.withValues(
            alpha: (0.15 + (_beatFlash * 0.1)) * opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 + beatThick
          ..strokeCap = StrokeCap.round
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawPoints(PointMode.polygon, points, glowPaint);
      }

      final corePaint = Paint()
        ..color = color.withValues(
          alpha: (0.85 + (_beatFlash * 0.15)) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (r == 0 ? beatThick : 0.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.polygon, points, corePaint);
    }

    // Label
    canvas.save();
    canvas.translate(startX, centerY + (_ekgMaxHeight / 2) + 12.0);
    _textPainter.text = TextSpan(
      text: 'EKG GUITAR (MID 250-2000Hz)',
      style: TextStyle(
        color: color.withValues(alpha: 0.45),
        fontSize: 8,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Render 150-sample circular EKG line orbiting the logo.
  void _renderCircularEKG(Canvas canvas) {
    final logoUV = game.smoothedLogoPos;
    final drift = _burnInDrift();
    final cx = logoUV.dx * game.size.x + (drift.dx * 0.4);
    final cy = logoUV.dy * game.size.y + (drift.dy * 0.4);

    final minDim = min(game.size.x, game.size.y);
    final baseRadius =
        (game.config.logoScale * minDim * 0.52 * game.config.ekgRadius).clamp(
          20.0,
          600.0,
        );

    final paletteColors =
        StealConfig.palettes[game.config.palette] ??
        StealConfig.palettes.values.first;
    final rawColor = paletteColors.isNotEmpty
        ? paletteColors.first
        : Colors.white;
    final hsl = HSLColor.fromColor(rawColor);
    final color = hsl
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.6).clamp(0.1, 1.0))
        .toColor()
        .withValues(alpha: 0.4);

    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      final opacity = (1.0 / (r + 1)) * color.a;
      final radiusOffset = r * spread;
      final beatThick = energy.isBeat ? 1.0 : 0.0;

      final points = <Offset>[];
      for (int i = 0; i < _ekgSampleCount; i++) {
        // Rotate history so newest is at the "top" or leading the circle
        final angle = (i / _ekgSampleCount) * 2 * pi - (pi / 2);
        final rad =
            baseRadius + radiusOffset + (_ekgHistory[i] * _ekgMaxHeight * 0.8);
        points.add(Offset(cx + rad * cos(angle), cy + rad * sin(angle)));
      }
      // Close the circle loop for PointMode.polygon
      points.add(points.first);

      if (r == 0 && _glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = color.withValues(
            alpha: (0.15 + (_beatFlash * 0.1)) * opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 + beatThick
          ..strokeCap = StrokeCap.round
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawPoints(PointMode.polygon, points, glowPaint);
      }

      final corePaint = Paint()
        ..color = color.withValues(
          alpha: (0.85 + (_beatFlash * 0.15)) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (r == 0 ? beatThick : 0.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.polygon, points, corePaint);
    }
  }

  /// Render 8-bar EQ + Beat anchored bottom-left using FFT band data.
  void _renderCorner(Canvas canvas) {
    final drift = _burnInDrift();
    final startY = game.size.y - _bottomPadding + drift.dy;
    final startX = _leftPadding + drift.dx;

    if (!_isFast) {
      _renderCornerHudPanel(canvas, startX, startY);
    }

    for (int i = 0; i < _cornerBarCount; i++) {
      final height = _cornerHeights[i].clamp(2.0, _maxBarHeight);
      final barLeft = startX + (i * (_barWidth + _barGap));
      final barTop = startY - height;
      final centerX = barLeft + (_barWidth / 2);
      final color = _bandColor(i);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, _barWidth, height),
        const Radius.circular(_cornerRadius),
      );

      if (_glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.22 + (_beatFlash * 0.18))
          ..style = PaintingStyle.fill
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawRRect(rect, glowPaint);
      }

      final corePaint = Paint()
        ..shader =
            Gradient.linear(Offset(barLeft, startY), Offset(barLeft, barTop), [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: i == _bandCount ? 0.98 : 0.88),
            ])
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, corePaint);

      final peakY = startY - _cornerPeakHeights[i].clamp(0.0, _maxBarHeight);
      final capPaint = Paint()
        ..color = color.withValues(alpha: 0.92)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(barLeft - 0.5, peakY),
        Offset(barLeft + _barWidth + 0.5, peakY),
        capPaint,
      );

      canvas.save();
      canvas.translate(centerX, startY + 6.0);
      canvas.rotate(-pi / 2);

      _textPainter.text = TextSpan(
        text: _cornerLabels[i],
        style: TextStyle(
          color: i == _bandCount
              ? Colors.white.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: i == _bandCount ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 1.0,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(-_textPainter.width, -_textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  void _renderCornerHudPanel(Canvas canvas, double startX, double startY) {
    const width =
        (_cornerBarCount * _barWidth) + ((_cornerBarCount - 1) * _barGap) + 18;
    const height = _maxBarHeight + 40;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX - 10, startY - _maxBarHeight - 14, width, height),
      const Radius.circular(10),
    );

    final panelPaint = Paint()
      ..color = Colors.white.withValues(alpha: _isBalanced ? 0.035 : 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(panelRect, panelPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14 + (_beatFlash * 0.1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(panelRect, borderPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    final top = startY - _maxBarHeight;
    for (int i = 1; i <= 3; i++) {
      final y = top + (_maxBarHeight / 4.0) * i;
      canvas.drawLine(
        Offset(startX - 7, y),
        Offset(startX - 7 + width - 6, y),
        linePaint,
      );
    }

    _textPainter.text = TextSpan(
      text: 'FFT 8B',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 8,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(startX - 2, startY + 16));
  }

  /// Render 8-band radial EQ centered on the logo.
  void _renderCircular(Canvas canvas) {
    final logoUV = game.smoothedLogoPos;
    final drift = _burnInDrift();
    final cx = logoUV.dx * game.size.x + (drift.dx * 0.4);
    final cy = logoUV.dy * game.size.y + (drift.dy * 0.4);

    final minDim = min(game.size.x, game.size.y);
    final dynamicRadius = (game.config.logoScale * minDim * 0.45).clamp(
      40.0,
      300.0,
    );

    for (int i = 0; i < _bandCount; i++) {
      final angle = (i / _bandCount) * 2 * pi - (pi / 2);
      final barHeight = _circularHeights[i].clamp(2.0, _circMaxBarHeight);
      final color = _bandColor(i);

      final innerR = dynamicRadius;
      final outerR = dynamicRadius + barHeight;

      final dirX = cos(angle);
      final dirY = sin(angle);
      final perpX = -dirY;
      final perpY = dirX;

      const halfW = _circBarWidth / 2;

      final path = Path()
        ..moveTo(
          cx + dirX * innerR + perpX * halfW,
          cy + dirY * innerR + perpY * halfW,
        )
        ..lineTo(
          cx + dirX * innerR - perpX * halfW,
          cy + dirY * innerR - perpY * halfW,
        )
        ..lineTo(
          cx + dirX * outerR - perpX * halfW,
          cy + dirY * outerR - perpY * halfW,
        )
        ..lineTo(
          cx + dirX * outerR + perpX * halfW,
          cy + dirY * outerR + perpY * halfW,
        )
        ..close();

      if (_glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.16 + (_beatFlash * 0.14))
          ..style = PaintingStyle.fill
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawPath(path, glowPaint);
      }

      final corePaint = Paint()
        ..shader = Gradient.linear(
          Offset(cx + dirX * innerR, cy + dirY * innerR),
          Offset(cx + dirX * outerR, cy + dirY * outerR),
          [color.withValues(alpha: 0.26), color.withValues(alpha: 0.9)],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, corePaint);

      final peakR =
          dynamicRadius + _circularPeakHeights[i].clamp(0.0, _circMaxBarHeight);
      final peakDot = Offset(cx + dirX * peakR, cy + dirY * peakR);
      final capPaint = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakDot, _isFast ? 1.0 : 1.8, capPaint);
    }
  }
}
