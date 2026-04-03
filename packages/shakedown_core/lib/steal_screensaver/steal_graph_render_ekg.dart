part of 'steal_graph.dart';

extension _StealGraphWaveRender on StealGraph {
  /// Render 150-sample horizontal EKG line across the bottom.
  void _renderEKG(Canvas canvas) {
    final drift = _burnInDrift();
    final w = game.size.x;
    final h = game.size.y;
    final centerY = h - _bottomPadding + drift.dy - (_ekgMaxHeight / 2);
    final startX = _leftPadding + drift.dx;
    final availableWidth = w - (_leftPadding * 2);

    final hsl = _ekgHsl;
    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      final t = replication > 1 ? r / (replication - 1) : 0.0;
      final lineColor = hsl
          .withLightness(
            (hsl.lightness * (0.55 + 0.45 * (1.0 - t))).clamp(0.15, 1.0),
          )
          .withSaturation(
            (hsl.saturation * (0.7 + 0.3 * (1.0 - t))).clamp(0.0, 1.0),
          )
          .toColor();
      final lineAlpha = 0.9 - t * 0.5;

      final verticalOffset = r * spread;
      final beatThick = energy.isBeat ? 1.2 : 0.0;

      final points = <Offset>[];
      for (int i = 0; i < _ekgSampleCount; i++) {
        final x = startX + (i / (_ekgSampleCount - 1)) * availableWidth;
        final y =
            centerY - (_ekgHistory[i] * _ekgMaxHeight) + (verticalOffset * 0.5);
        points.add(Offset(x, y));
      }

      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i + 1 < points.length; i++) {
        final midX = (points[i].dx + points[i + 1].dx) / 2;
        final midY = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, midX, midY);
      }
      path.lineTo(points.last.dx, points.last.dy);

      if (r == 0 && _glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = lineColor.withValues(
            alpha: (0.18 + (_beatFlash * 0.28)) * lineAlpha,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0 + beatThick
          ..strokeCap = StrokeCap.round
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawPath(path, glowPaint);
      }

      final corePaint = Paint()
        ..color = lineColor.withValues(
          alpha: (0.85 + (_beatFlash * 0.15)) * lineAlpha,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (r == 0 ? beatThick : 0.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, corePaint);
    }

    canvas.save();
    canvas.translate(startX, centerY + (_ekgMaxHeight / 2) + 12.0);
    _textPainter.text = TextSpan(
      text: 'EKG GUITAR (MID 250-2000Hz)',
      style: TextStyle(
        color: _ekgHsl.toColor().withValues(alpha: 0.45),
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

    final hsl = _ekgHsl;
    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      final t = replication > 1 ? r / (replication - 1) : 0.0;
      final lineColor = hsl
          .withLightness(
            (hsl.lightness * (0.55 + 0.45 * (1.0 - t))).clamp(0.15, 1.0),
          )
          .withSaturation(
            (hsl.saturation * (0.7 + 0.3 * (1.0 - t))).clamp(0.0, 1.0),
          )
          .toColor();
      final lineAlpha = 0.9 - t * 0.5;

      final radiusOffset = r * spread;
      final beatThick = energy.isBeat ? 2.0 : 0.0;

      final points = <Offset>[];
      for (int i = 0; i < _ekgSampleCount; i++) {
        final angle = (i / _ekgSampleCount) * 2 * pi - (pi / 2) + _ekgRotation;
        final rad =
            baseRadius + radiusOffset + (_ekgHistory[i] * _ekgMaxHeight * 0.8);
        points.add(Offset(cx + rad * cos(angle), cy + rad * sin(angle)));
      }

      final path = Path();
      final startMid = Offset(
        (points.last.dx + points[0].dx) / 2,
        (points.last.dy + points[0].dy) / 2,
      );
      path.moveTo(startMid.dx, startMid.dy);
      for (int i = 0; i < points.length; i++) {
        final next = points[(i + 1) % points.length];
        final midX = (points[i].dx + next.dx) / 2;
        final midY = (points[i].dy + next.dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, midX, midY);
      }

      if (r == 0 && _glowSigma > 0.0) {
        final glowPaint = Paint()
          ..color = lineColor.withValues(
            alpha: (0.18 + (_beatFlash * 0.35)) * lineAlpha,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0 + beatThick
          ..strokeCap = StrokeCap.round
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, _glowSigma);
        canvas.drawPath(path, glowPaint);
      }

      final corePaint = Paint()
        ..color = lineColor.withValues(
          alpha: (0.85 + (_beatFlash * 0.15)) * lineAlpha,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (r == 0 ? beatThick : 0.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, corePaint);
    }
  }

  /// Render 8-band radial EQ centered on the logo.
  void _renderCircular(Canvas canvas) {
    final logoUV = game.smoothedLogoPos;
    final drift = _burnInDrift();
    final cx = logoUV.dx * game.size.x + (drift.dx * 0.4);
    final cy = logoUV.dy * game.size.y + (drift.dy * 0.4);

    final minDim = min(game.size.x, game.size.y);
    final dynamicRadius =
        (game.config.logoScale *
                minDim *
                0.45 *
                game.pulseScale *
                game.config.ekgRadius)
            .clamp(40.0, 300.0);

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
