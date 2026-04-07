part of 'steal_graph.dart';

extension _StealGraphCornerRender on StealGraph {
  TextStyle _monoTextStyle({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontFamily: 'RobotoMono',
    );
  }

  void _paintMonoText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required TextStyle style,
  }) {
    _textPainter
      ..text = TextSpan(text: text, style: style)
      ..layout();
    _textPainter.paint(canvas, offset);
  }

  void _paintRightAlignedMonoText(
    Canvas canvas, {
    required String text,
    required double right,
    required double top,
    required TextStyle style,
  }) {
    _textPainter
      ..text = TextSpan(text: text, style: style)
      ..layout();
    _textPainter.paint(canvas, Offset(right - _textPainter.width, top));
  }

  void _paintCenteredMonoText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required TextStyle style,
  }) {
    _textPainter
      ..text = TextSpan(text: text, style: style)
      ..layout();
    _textPainter.paint(
      canvas,
      Offset(
        center.dx - (_textPainter.width / 2),
        center.dy - (_textPainter.height / 2),
      ),
    );
  }

  void _paintRotatedCornerLabel(
    Canvas canvas, {
    required String text,
    required double centerX,
    required double baselineY,
    required TextStyle style,
  }) {
    canvas.save();
    canvas.translate(centerX, baselineY);
    canvas.rotate(-pi / 2);
    _textPainter
      ..text = TextSpan(text: text, style: style)
      ..layout();
    _textPainter.paint(
      canvas,
      Offset(-_textPainter.width, -_textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawPanelChrome(
    Canvas canvas,
    RRect panelRect, {
    required double fillAlpha,
    required double borderAlpha,
  }) {
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Paint _strokePaint({
    required Color color,
    required double width,
    StrokeCap strokeCap = StrokeCap.round,
  }) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = strokeCap;
  }

  Paint _glowFillPaint({required Color color, required double sigma}) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = isWasmSafeMode()
          ? null
          : MaskFilter.blur(BlurStyle.normal, sigma);
  }

  Paint _glowStrokePaint({
    required Color color,
    required double width,
    required double sigma,
    StrokeCap strokeCap = StrokeCap.round,
  }) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = strokeCap
      ..maskFilter = isWasmSafeMode()
          ? null
          : MaskFilter.blur(BlurStyle.normal, sigma);
  }

  Path _buildWaveformPath({
    required List<double> waveform,
    required double startX,
    required double availableWidth,
    required double centerY,
    required double laneHeight,
    required double Function(double value) normalize,
  }) {
    final path = Path();
    path.moveTo(startX, centerY - normalize(waveform.first) * (laneHeight / 2));
    for (int i = 1; i < waveform.length; i++) {
      final x = startX + (i / (waveform.length - 1)) * availableWidth;
      final y = centerY - normalize(waveform[i]) * (laneHeight / 2);
      path.lineTo(x, y);
    }
    return path;
  }

  void _drawTrace(
    Canvas canvas, {
    required Path path,
    required Color traceColor,
    required double glowAlpha,
    required double glowWidth,
    required double lineAlpha,
    required double lineWidth,
  }) {
    if (_glowSigma > 0.0) {
      canvas.drawPath(
        path,
        _glowStrokePaint(
          color: traceColor.withValues(alpha: glowAlpha),
          width: glowWidth,
          sigma: _glowSigma,
        ),
      );
    }
    canvas.drawPath(
      path,
      _strokePaint(
        color: traceColor.withValues(alpha: lineAlpha),
        width: lineWidth,
      ),
    );
  }

  /// Render 8-bar EQ + beat anchored bottom-left using FFT band data.
  void _renderCorner(Canvas canvas) {
    final drift = _burnInDrift();
    final startY = _logicalSize.y - _bottomPadding + drift.dy;
    final startX = _leftPadding + drift.dx;

    if (!_isFast) {
      _renderCornerHudPanel(canvas, startX, startY);
    }

    for (int i = 0; i < _cornerBarCount; i++) {
      final isBeatBar = i == _bandCount;
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
        final glowAlpha = isBeatBar
            ? (0.35 + _beatFlash * 0.55).clamp(0.0, 1.0)
            : (0.22 + _beatFlash * 0.18).clamp(0.0, 1.0);
        final glowSigma = isBeatBar ? _glowSigma * 2.0 : _glowSigma;
        canvas.drawRRect(
          rect,
          _glowFillPaint(
            color: color.withValues(alpha: glowAlpha),
            sigma: glowSigma,
          ),
        );
      }

      final topAlpha = isBeatBar
          ? (0.75 + _beatFlash * 0.25).clamp(0.0, 1.0)
          : 0.88;
      final corePaint = Paint()
        ..shader = Gradient.linear(
          Offset(barLeft, startY),
          Offset(barLeft, barTop),
          [color.withValues(alpha: 0.24), color.withValues(alpha: topAlpha)],
        )
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, corePaint);

      if (isBeatBar && _beatFlash > 0.45) {
        final sparkAlpha = ((_beatFlash - 0.45) / 0.55).clamp(0.0, 1.0);
        canvas.drawLine(
          Offset(barLeft - 1.0, barTop),
          Offset(barLeft + _barWidth + 1.0, barTop),
          _strokePaint(
            color: Colors.white.withValues(alpha: sparkAlpha * 0.95),
            width: 2.0,
          ),
        );
      }

      final peakY = startY - _cornerPeakHeights[i].clamp(0.0, _maxBarHeight);
      canvas.drawLine(
        Offset(barLeft - 0.5, peakY),
        Offset(barLeft + _barWidth + 0.5, peakY),
        _strokePaint(color: color.withValues(alpha: 0.92), width: 1.3),
      );

      _paintRotatedCornerLabel(
        canvas,
        text: _cornerLabels[i],
        centerX: centerX,
        baselineY: startY + 6.0,
        style: _monoTextStyle(
          color: isBeatBar
              ? Colors.white.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: isBeatBar ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );
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

    _drawPanelChrome(
      canvas,
      panelRect,
      fillAlpha: _isBalanced ? 0.035 : 0.06,
      borderAlpha: 0.14 + (_beatFlash * 0.1),
    );

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

    _paintMonoText(
      canvas,
      text: 'FFT 8B',
      offset: Offset(startX - 2, startY + 16),
      style: _monoTextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 8,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }

  /// Render phosphor oscilloscope.
  ///
  /// When [panelWidth] is provided the scope is right-anchored with a fixed
  /// panel width matching the bar-graph panel footprint.
  void _renderScope(Canvas canvas, {double? panelWidth}) {
    final drift = _burnInDrift();
    final w = _logicalSize.x;
    final h = _logicalSize.y;

    final isPanelMode = panelWidth != null;
    final scopeHeight = isPanelMode ? _maxBarHeight : 70.0;
    final availableWidth = isPanelMode ? panelWidth : w - _leftPadding * 2;
    final startX =
        (isPanelMode ? w - _leftPadding - panelWidth : _leftPadding) + drift.dx;
    final centerY =
        h - _bottomPadding + drift.dy - (isPanelMode ? scopeHeight / 2 : 0.0);

    const phosphorColor = Color(0xFF33FF66);
    double softClip(double v) => atan(v * 50.0) / (pi / 2);

    if (isPanelMode && !_isFast) {
      const panelPad = 10.0;
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX - panelPad,
          centerY - scopeHeight / 2 - 14,
          availableWidth + panelPad * 2,
          scopeHeight + 40,
        ),
        const Radius.circular(10),
      );
      _drawPanelChrome(
        canvas,
        panelRect,
        fillAlpha: _isBalanced ? 0.035 : 0.06,
        borderAlpha: 0.14 + _beatFlash * 0.1,
      );
    }

    final graticulePaint = Paint()
      ..color = phosphorColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(startX + availableWidth, centerY),
      graticulePaint,
    );
    for (final yOff in [-scopeHeight / 2, scopeHeight / 2]) {
      canvas.drawLine(
        Offset(startX, centerY + yOff),
        Offset(startX + availableWidth, centerY + yOff),
        graticulePaint,
      );
    }

    final traceColor = _beatFlash > 0.01
        ? Color.lerp(phosphorColor, const Color(0xFFFFFFFF), _beatFlash * 0.5)!
        : phosphorColor;

    final waveform = _scopeWaveform;
    final hasPcm = waveform.length >= 2 && _scopePeak > 0.015;
    final hasStereoScope =
        isPanelMode &&
        _scopeWaveformL.length >= 2 &&
        _scopeWaveformR.length >= 2 &&
        max(_scopePeakL, _scopePeakR) > 0.015;

    if (hasStereoScope) {
      final upperCenterY = centerY - scopeHeight * 0.24;
      final lowerCenterY = centerY + scopeHeight * 0.24;
      final laneHeight = scopeHeight * 0.42;
      const leftColor = Color(0xFF5DFFB2);
      const rightColor = Color(0xFF55D9FF);

      for (final laneY in [upperCenterY, lowerCenterY]) {
        canvas.drawLine(
          Offset(startX, laneY),
          Offset(startX + availableWidth, laneY),
          _strokePaint(
            color: phosphorColor.withValues(alpha: 0.08),
            width: 0.5,
            strokeCap: StrokeCap.butt,
          ),
        );
      }

      _drawTrace(
        canvas,
        path: _buildWaveformPath(
          waveform: _scopeWaveformL,
          startX: startX,
          availableWidth: availableWidth,
          centerY: upperCenterY,
          laneHeight: laneHeight,
          normalize: softClip,
        ),
        traceColor: leftColor,
        glowAlpha: 0.18 + _beatFlash * 0.18,
        glowWidth: 3.0,
        lineAlpha: 0.92,
        lineWidth: 1.2 + _beatFlash * 0.6,
      );
      _drawTrace(
        canvas,
        path: _buildWaveformPath(
          waveform: _scopeWaveformR,
          startX: startX,
          availableWidth: availableWidth,
          centerY: lowerCenterY,
          laneHeight: laneHeight,
          normalize: softClip,
        ),
        traceColor: rightColor,
        glowAlpha: 0.18 + _beatFlash * 0.18,
        glowWidth: 3.0,
        lineAlpha: 0.92,
        lineWidth: 1.2 + _beatFlash * 0.6,
      );

      _paintMonoText(
        canvas,
        text: 'OSC PCM ST  256pt',
        offset: Offset(startX, centerY + scopeHeight / 2 + 6.0),
        style: _monoTextStyle(
          color: phosphorColor.withValues(alpha: 0.42),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      );

      _paintRightAlignedMonoText(
        canvas,
        text:
            'L ${(_scopePeakL * 100).clamp(0.0, 100.0).toStringAsFixed(0).padLeft(3)}%  '
            'R ${(_scopePeakR * 100).clamp(0.0, 100.0).toStringAsFixed(0).padLeft(3)}%',
        right: startX + availableWidth,
        top: centerY + scopeHeight / 2 + 6.0,
        style: _monoTextStyle(
          color: phosphorColor.withValues(alpha: 0.32),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );

      _paintMonoText(
        canvas,
        text: 'L',
        offset: Offset(startX + 4, upperCenterY - laneHeight / 2),
        style: _monoTextStyle(
          color: leftColor.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

      _paintMonoText(
        canvas,
        text: 'R',
        offset: Offset(startX + 4, lowerCenterY - laneHeight / 2),
        style: _monoTextStyle(
          color: rightColor.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
      return;
    }

    if (hasPcm) {
      _drawTrace(
        canvas,
        path: _buildWaveformPath(
          waveform: waveform,
          startX: startX,
          availableWidth: availableWidth,
          centerY: centerY,
          laneHeight: scopeHeight,
          normalize: softClip,
        ),
        traceColor: traceColor,
        glowAlpha: 0.22 + _beatFlash * 0.28,
        glowWidth: 4.0,
        lineAlpha: 0.92,
        lineWidth: 1.5 + _beatFlash * 0.8,
      );

      _paintMonoText(
        canvas,
        text: 'OSC PCM  256pt',
        offset: Offset(startX, centerY + scopeHeight / 2 + 6.0),
        style: _monoTextStyle(
          color: phosphorColor.withValues(alpha: 0.4),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      );

      final peakPct = (_scopePeak * 100).clamp(0.0, 100.0).toStringAsFixed(0);
      _paintRightAlignedMonoText(
        canvas,
        text: 'LVL $peakPct%',
        right: startX + availableWidth,
        top: centerY + scopeHeight / 2 + 6.0,
        style: _monoTextStyle(
          color: phosphorColor.withValues(alpha: 0.3),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );
    } else {
      final bands = energy.bands;
      final hasSignal = bands.length >= 8 && energy.overall > 0.008;

      if (hasSignal) {
        const freqs = [0.2, 0.4, 0.7, 1.1, 1.6, 2.25, 3.0, 4.0];
        const windowSecs = 4.0;
        const numPoints = 128;

        final t = game.time;
        final amps = List<double>.generate(
          8,
          (b) => b < bands.length ? softClip(bands[b] * 3.0) : 0.0,
        );

        final path = Path();
        for (int i = 0; i < numPoints; i++) {
          final x = startX + (i / (numPoints - 1)) * availableWidth;
          final tx = t - windowSecs + (i / (numPoints - 1)) * windowSecs;
          var val = 0.0;
          for (int b = 0; b < 8; b++) {
            val += amps[b] * sin(2 * pi * freqs[b] * tx);
          }
          val = (val / 4.0).clamp(-1.0, 1.0);
          final y = centerY - val * (scopeHeight / 2);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        _drawTrace(
          canvas,
          path: path,
          traceColor: traceColor,
          glowAlpha: 0.22 + _beatFlash * 0.28,
          glowWidth: 4.0,
          lineAlpha: 0.92,
          lineWidth: 1.5 + _beatFlash * 0.8,
        );

        _paintMonoText(
          canvas,
          text: 'OSC FFT-SYN  8B',
          offset: Offset(startX, centerY + scopeHeight / 2 + 6.0),
          style: _monoTextStyle(
            color: phosphorColor.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        );
      } else {
        final flatAlpha = 0.15 + energy.overall * 0.35 + _beatFlash * 0.3;
        canvas.drawLine(
          Offset(startX, centerY),
          Offset(startX + availableWidth, centerY),
          _strokePaint(
            color: phosphorColor.withValues(alpha: flatAlpha.clamp(0.0, 1.0)),
            width: 1.2,
            strokeCap: StrokeCap.butt,
          ),
        );

        _paintMonoText(
          canvas,
          text: 'OSC - SILENT',
          offset: Offset(startX, centerY + scopeHeight / 2 + 6.0),
          style: _monoTextStyle(
            color: phosphorColor.withValues(alpha: 0.25),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        );
      }
    }
  }

  /// Render dual VU needle meters.
  void _renderVu(Canvas canvas) {
    final drift = _burnInDrift();
    final cx = _logicalSize.x / 2 + drift.dx;
    final baseY = _logicalSize.y - _bottomPadding + drift.dy;
    const gap = 60.0;
    final lRange = _hasRealStereo ? 'ST' : 'LO';
    final rRange = _hasRealStereo ? 'ST' : 'HI';

    _drawVuMeter(
      canvas,
      cx - _vuWidth - gap / 2,
      baseY,
      _vuLeft,
      _vuPeakLeft,
      _vuRawLeft,
      'L',
      lRange,
      _vuDrive,
    );
    _drawLedStrip(canvas, cx, baseY);
    _drawVuMeter(
      canvas,
      cx + gap / 2,
      baseY,
      _vuRight,
      _vuPeakRight,
      _vuRawRight,
      'R',
      rRange,
      _vuDrive,
    );
  }

  void _drawVuMeter(
    Canvas canvas,
    double left,
    double bottom,
    double level,
    double peakLevel,
    double rawLevel,
    String chanLabel,
    String rangeLabel,
    double drive,
  ) {
    if (!_isFast) {
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bottom - _vuHeight, _vuWidth, _vuHeight),
        const Radius.circular(8),
      );
      _drawPanelChrome(
        canvas,
        panelRect,
        fillAlpha: 0.05,
        borderAlpha: 0.12 + _beatFlash * 0.06,
      );
    }

    final pivotX = left + _vuWidth / 2;
    final pivotY = bottom - 14.0;
    const arcRadius = _vuNeedleLength + 5.0;
    final arcRect = Rect.fromCenter(
      center: Offset(pivotX, pivotY),
      width: _vuNeedleLength * 2,
      height: _vuNeedleLength * 2,
    );
    const arcStart = -pi / 2 - _vuSweepHalf;
    const totalSweep = _vuSweepHalf * 2;

    canvas.drawArc(
      arcRect,
      arcStart,
      totalSweep * 0.65,
      false,
      _strokePaint(
        color: const Color(0xFF4AF3C6).withValues(alpha: 0.10),
        width: 5.0,
      ),
    );
    canvas.drawArc(
      arcRect,
      arcStart + totalSweep * 0.65,
      totalSweep * 0.17,
      false,
      _strokePaint(
        color: const Color(0xFFFFE66D).withValues(alpha: 0.12),
        width: 5.0,
      ),
    );
    canvas.drawArc(
      arcRect,
      arcStart + totalSweep * 0.82,
      totalSweep * 0.18,
      false,
      _strokePaint(
        color: const Color(0xFFFF4444).withValues(alpha: 0.15),
        width: 5.0,
      ),
    );

    const markFracs = [0.0, 0.2, 0.4, 0.58, 0.72, 0.84, 1.0];
    const markLabels = ['-20', '-10', '-7', '-3', '0', '+1', '+3'];
    const showLabel = [true, false, false, false, true, false, true];

    for (int m = 0; m < markFracs.length; m++) {
      final frac = markFracs[m];
      final angle = -pi / 2 + (-_vuSweepHalf + frac * totalSweep);
      final mx1 = pivotX + cos(angle) * arcRadius;
      final my1 = pivotY + sin(angle) * arcRadius;
      final mx2 =
          pivotX + cos(angle) * (arcRadius + (frac == 0.72 ? 9.0 : 6.0));
      final my2 =
          pivotY + sin(angle) * (arcRadius + (frac == 0.72 ? 9.0 : 6.0));

      final tickColor = frac < 0.65
          ? const Color(0xFF4AF3C6)
          : frac < 0.82
          ? const Color(0xFFFFE66D)
          : const Color(0xFFFF5555);

      canvas.drawLine(
        Offset(mx1, my1),
        Offset(mx2, my2),
        _strokePaint(
          color: tickColor.withValues(alpha: 0.65),
          width: frac == 0.72 ? 1.5 : 0.8,
        ),
      );

      if (showLabel[m]) {
        _textPainter
          ..text = TextSpan(
            text: markLabels[m],
            style: _monoTextStyle(
              color: tickColor.withValues(alpha: 0.55),
              fontSize: 7,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
          )
          ..layout();
        final lx =
            pivotX + cos(angle) * (arcRadius + 15) - _textPainter.width / 2;
        final ly =
            pivotY + sin(angle) * (arcRadius + 15) - _textPainter.height / 2;
        _textPainter.paint(canvas, Offset(lx, ly));
      }
    }

    final needleLevel = level.clamp(0.0, 1.0);
    final needleAngle = -pi / 2 + (-_vuSweepHalf + needleLevel * totalSweep);
    final tipX = pivotX + cos(needleAngle) * _vuNeedleLength;
    final tipY = pivotY + sin(needleAngle) * _vuNeedleLength;
    const spindleRadius = 4.5;
    final needleStartX = pivotX + cos(needleAngle) * spindleRadius;
    final needleStartY = pivotY + sin(needleAngle) * spindleRadius;

    final needleColor = needleLevel < 0.65
        ? const Color(0xFFDDDDDD)
        : needleLevel < 0.82
        ? const Color(0xFFFFE66D)
        : const Color(0xFFFF5555);

    if (_glowSigma > 0.0 && needleLevel > 0.05) {
      canvas.drawLine(
        Offset(needleStartX, needleStartY),
        Offset(tipX, tipY),
        _glowStrokePaint(
          color: needleColor.withValues(alpha: 0.18),
          width: 3.0,
          sigma: 4.0,
        ),
      );
    }
    canvas.drawLine(
      Offset(needleStartX, needleStartY),
      Offset(tipX, tipY),
      _strokePaint(color: needleColor.withValues(alpha: 0.95), width: 1.4),
    );

    canvas.drawCircle(
      Offset(pivotX, pivotY),
      4.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(pivotX, pivotY),
      4.5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    _paintMonoText(
      canvas,
      text: chanLabel,
      offset: Offset(left + 7, bottom - _vuHeight + 6),
      style: _monoTextStyle(
        color: const Color(0xFF99AABB),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
    _paintRightAlignedMonoText(
      canvas,
      text: rangeLabel,
      right: left + _vuWidth - 7,
      top: bottom - _vuHeight + 6,
      style: _monoTextStyle(
        color: const Color(0xFF667788).withValues(alpha: 0.8),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );

    final rawPct = (rawLevel * 100).clamp(0.0, 100.0).toStringAsFixed(0);
    _paintMonoText(
      canvas,
      text: 'SIG ${rawPct.padLeft(3)}%',
      offset: Offset(left + 7, bottom - 18),
      style: _monoTextStyle(
        color: const Color(0xFF7FA0B8).withValues(alpha: 0.75),
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
    );
    _paintRightAlignedMonoText(
      canvas,
      text: 'x${drive.toStringAsFixed(1)}',
      right: left + _vuWidth - 7,
      top: bottom - 18,
      style: _monoTextStyle(
        color: const Color(0xFF667788).withValues(alpha: 0.8),
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
    );
    _paintCenteredMonoText(
      canvas,
      text: 'VU',
      center: Offset(pivotX, bottom - 6),
      style: _monoTextStyle(
        color: const Color(0xFF445566),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  void _drawLedStrip(Canvas canvas, double cx, double baseY) {
    final stripLeft = cx - _ledStripWidth / 2;
    const stripHeight = _vuHeight;
    const usableHeight = stripHeight - _ledLabelReserve;
    const segH =
        (usableHeight - (_ledSegmentCount - 1) * _ledSegGap) / _ledSegmentCount;
    const colW = (_ledStripWidth - _ledHPad * 2 - _ledColGap) / 2;

    if (!_isFast) {
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          stripLeft,
          baseY - stripHeight,
          _ledStripWidth,
          stripHeight,
        ),
        const Radius.circular(4),
      );
      _drawPanelChrome(
        canvas,
        panelRect,
        fillAlpha: 0.05,
        borderAlpha: 0.12 + _beatFlash * 0.06,
      );
    }

    final leftActive = (_vuLeft.clamp(0.0, 1.0) * (_ledSegmentCount - 1))
        .round();
    final rightActive = (_vuRight.clamp(0.0, 1.0) * (_ledSegmentCount - 1))
        .round();
    final leftPeakIdx = _vuPeakLeft > 0.02
        ? (_vuPeakLeft.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round()
        : -1;
    final rightPeakIdx = _vuPeakRight > 0.02
        ? (_vuPeakRight.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round()
        : -1;

    for (int seg = 0; seg < _ledSegmentCount; seg++) {
      final Color zoneColor;
      if (seg >= 13) {
        zoneColor = const Color(0xFFFF4444);
      } else if (seg >= 10) {
        zoneColor = const Color(0xFFFFE66D);
      } else {
        zoneColor = const Color(0xFF4AF3C6);
      }

      final segBottom = baseY - _ledLabelReserve - seg * (segH + _ledSegGap);
      final segTop = segBottom - segH;

      final lColLeft = stripLeft + _ledHPad;
      _drawLedSegment(
        canvas,
        Rect.fromLTRB(lColLeft, segTop, lColLeft + colW, segBottom),
        zoneColor,
        seg <= leftActive,
        seg == leftPeakIdx,
      );

      final rColLeft = stripLeft + _ledHPad + colW + _ledColGap;
      _drawLedSegment(
        canvas,
        Rect.fromLTRB(rColLeft, segTop, rColLeft + colW, segBottom),
        zoneColor,
        seg <= rightActive,
        seg == rightPeakIdx,
      );
    }

    final lLabelX = stripLeft + _ledHPad + colW / 2;
    final rLabelX = stripLeft + _ledHPad + colW + _ledColGap + colW / 2;
    for (final entry in [('L', lLabelX), ('R', rLabelX)]) {
      _paintCenteredMonoText(
        canvas,
        text: entry.$1,
        center: Offset(entry.$2, baseY - _ledLabelReserve + 7),
        style: _monoTextStyle(
          color: Color(0xFF445566),
          fontSize: 6,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );
    }
  }

  void _drawLedSegment(
    Canvas canvas,
    Rect rect,
    Color zoneColor,
    bool isActive,
    bool isPeak,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = zoneColor.withValues(alpha: isActive ? 0.85 : 0.08)
        ..style = PaintingStyle.fill,
    );
    if (isPeak) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = zoneColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }
}
