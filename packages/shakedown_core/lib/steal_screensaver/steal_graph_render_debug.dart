part of 'steal_graph.dart';

extension _StealGraphDebugRender on StealGraph {
  /// Beat algorithm comparison display.
  void _renderBeatDebug(Canvas canvas) {
    const numAlgos = 6;
    const barW = 64.0;
    const barGap = 18.0;
    const maxH = 140.0;
    const bottomPad = 100.0;
    const labelH = 32.0;
    const panelPad = 20.0;

    final w = _logicalSize.x;
    final h = _logicalSize.y;
    const totalW = numAlgos * barW + (numAlgos - 1) * barGap;
    final startX = (w - totalW) / 2;
    final baseY = h - bottomPad;
    final beatSensitivity = game.config.beatSensitivity.clamp(0.0, 1.0);
    final payloadThresholds = energy.algoThresholds;
    final meanThreshold =
        payloadThresholds.length > 1 && payloadThresholds[1] > 0.0
        ? payloadThresholds[1]
        : 1.2 + (1.0 - beatSensitivity) * 1.0;
    final emaThreshold =
        payloadThresholds.length > 4 && payloadThresholds[4] > 0.0
        ? payloadThresholds[4]
        : 1.0 + (1.0 - beatSensitivity) * 0.5;
    final winningAlgoId = energy.winningAlgoId;
    final beatSource = energy.beatSource ?? '--';
    final hintTitle = game.config.trackHintTitle;
    final hintVariant = game.config.trackHintVariant;
    final hintId = game.config.trackHintId;
    final hintSeedSource = game.config.trackHintSeedSource.toUpperCase();
    final winningLabel =
        winningAlgoId != null &&
            winningAlgoId >= 0 &&
            winningAlgoId < _algoLabels.length
        ? _algoLabels[winningAlgoId].split('\n').first
        : '--';

    String formatTelemetry(double? value, {int digits = 2}) =>
        value == null ? '--' : value.toStringAsFixed(digits);

    final hasHint = hintId.isNotEmpty;
    final metaSummary = hasHint
        ? 'META:${hintTitle.isNotEmpty ? hintTitle : hintId}  '
              'VAR:${hintVariant.isEmpty ? "main" : hintVariant}  '
              'SEED:$hintSeedSource'
        : 'META:--  VAR:--  SEED:$hintSeedSource';
    final trackingSummary =
        'PH:${formatTelemetry(energy.beatPhase)}  '
        'NXT:${formatTelemetry(energy.nextBeatMs, digits: 0)}  '
        'GRID:${formatTelemetry(energy.beatGridConfidence)}';
    final pcmStatus = !energy.debugPcmActive
        ? 'OFF'
        : (energy.debugPcmFresh ? 'HOT' : 'STALE');
    final pcmFrames = energy.debugPcmAnalysisFrames?.toString() ?? '--';
    final pcmAge = formatTelemetry(energy.debugPcmAgeMs, digits: 0);
    final pcmSummary = 'PCM:$pcmStatus  FR:$pcmFrames  AGE:$pcmAge';
    final panelTextLeft = startX - panelPad + 12.0;
    const panelTextWidth = totalW + panelPad * 2 - 24.0;
    final panelTop = baseY - maxH - 84.0;
    final statusLineY = panelTop + 10.0;
    final debugLine1Y = panelTop + 24.0;
    final debugLine2Y = panelTop + 38.0;
    final metaLineY = panelTop + 54.0;
    final trackingLineY = panelTop + 66.0;
    final col1 = panelTextLeft;
    final col2 = panelTextLeft + 94.0;
    final col3 = panelTextLeft + 220.0;
    final col4 = panelTextLeft + 320.0;
    final col5 = panelTextLeft + 412.0;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startX - panelPad,
        baseY - maxH - 84,
        totalW + panelPad * 2,
        maxH + labelH + 96,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final sessionStr = debugSessionId?.toString() ?? 'null';
    final reactorStr = debugReactorConnected ? 'YES' : 'NO';
    final rawBass = _padLeftField((energy.bass * 100).toStringAsFixed(0), 3);
    final rawMid = _padLeftField((energy.mid * 100).toStringAsFixed(0), 3);
    final rawTreb = _padLeftField((energy.treble * 100).toStringAsFixed(0), 3);
    final statusStyle = TextStyle(
      color: debugReactorConnected
          ? const Color(0xFF55FF88).withValues(alpha: 0.7)
          : const Color(0xFFFF5555).withValues(alpha: 0.7),
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      fontFamily: 'RobotoMono',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    _paintDebugText(
      canvas,
      'SID:${_padRightField(sessionStr, 4)}',
      statusStyle,
      col1,
      statusLineY,
      maxWidth: 88,
    );
    _paintDebugText(
      canvas,
      'REACTOR:${_padRightField(reactorStr, 3)}',
      statusStyle,
      col2,
      statusLineY,
      maxWidth: 120,
    );
    _paintDebugText(
      canvas,
      'BASS:$rawBass%',
      statusStyle,
      col3,
      statusLineY,
      maxWidth: 88,
    );
    _paintDebugText(
      canvas,
      'MID:$rawMid%',
      statusStyle,
      col4,
      statusLineY,
      maxWidth: 82,
    );
    _paintDebugText(
      canvas,
      'TREB:$rawTreb%',
      statusStyle,
      col5,
      statusLineY,
      maxWidth: 90,
    );

    final beatSourceField = _padRightField(beatSource, 6);
    final winningField = _padRightField(winningLabel, 5);
    final bpmField = _padLeftField(
      formatTelemetry(energy.beatBpm, digits: 1),
      5,
    );
    final ibiField = _padLeftField(
      formatTelemetry(energy.beatIbiMs, digits: 0),
      4,
    );
    final debugLineStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      fontFamily: 'RobotoMono',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    _paintDebugText(
      canvas,
      'BEAT DEBUG',
      debugLineStyle,
      col1,
      debugLine1Y,
      maxWidth: 108,
    );
    _paintDebugText(
      canvas,
      'SENS:${beatSensitivity.toStringAsFixed(2)}',
      debugLineStyle,
      col2,
      debugLine1Y,
      maxWidth: 96,
    );
    _paintDebugText(
      canvas,
      'OVR:${(energy.overall * 100).toStringAsFixed(0).padLeft(3)}%',
      debugLineStyle,
      col3,
      debugLine1Y,
      maxWidth: 92,
    );
    _paintDebugText(
      canvas,
      'SCR:${energy.beatScore.toStringAsFixed(2)}',
      debugLineStyle,
      col4,
      debugLine1Y,
      maxWidth: 86,
    );
    _paintDebugText(
      canvas,
      'THR:${energy.beatThreshold.toStringAsFixed(2)}',
      debugLineStyle,
      col5,
      debugLine1Y,
      maxWidth: 90,
    );
    _paintDebugText(
      canvas,
      'SRC:$beatSourceField',
      debugLineStyle,
      col1,
      debugLine2Y,
      maxWidth: 110,
    );
    _paintDebugText(
      canvas,
      'WIN:$winningField',
      debugLineStyle,
      col2,
      debugLine2Y,
      maxWidth: 96,
    );
    _paintDebugText(
      canvas,
      'BPM:$bpmField',
      debugLineStyle,
      col3,
      debugLine2Y,
      maxWidth: 96,
    );
    _paintDebugText(
      canvas,
      'IBI:$ibiField',
      debugLineStyle,
      col4,
      debugLine2Y,
      maxWidth: 82,
    );
    _paintDebugText(
      canvas,
      'CNF:${energy.beatConfidence.toStringAsFixed(2)}',
      debugLineStyle,
      col5,
      debugLine2Y,
      maxWidth: 90,
    );

    final metaStyle = TextStyle(
      color: hasHint
          ? const Color(0xFF7FD8FF).withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.35),
      fontSize: 8,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      fontFamily: 'RobotoMono',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final trackingStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.46),
      fontSize: 8,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      fontFamily: 'RobotoMono',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    _paintDebugText(
      canvas,
      metaSummary,
      metaStyle,
      col1,
      metaLineY,
      maxWidth: panelTextWidth,
      maxLines: 1,
      ellipsis: '...',
    );
    _paintDebugText(
      canvas,
      trackingSummary,
      trackingStyle,
      col1,
      trackingLineY,
      maxWidth: 220,
      maxLines: 1,
      ellipsis: '...',
    );
    _paintDebugText(
      canvas,
      pcmSummary,
      trackingStyle,
      col3,
      trackingLineY,
      maxWidth: 230,
      maxLines: 1,
      ellipsis: '...',
    );

    final finalRatio = energy.beatThreshold > 0.0
        ? (energy.beatScore / energy.beatThreshold).clamp(0.0, 2.0)
        : 0.0;
    final finalMeterLeft = startX - panelPad + 8;
    final finalMeterTop = panelTop + 112.0;
    const finalMeterWidth = totalW + panelPad * 2 - 16;
    const finalMeterHeight = 10.0;
    final finalColor = beatSource == 'PCM'
        ? const Color(0xFF55D9FF)
        : const Color(0xFFFFB84D);

    _textPainter.text = TextSpan(
      text: 'FINAL $beatSource',
      style: TextStyle(
        color: finalColor.withValues(alpha: 0.72),
        fontSize: 7,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(finalMeterLeft, finalMeterTop - 10));
    final finalLabelWidth = _textPainter.width;

    _textPainter.text = TextSpan(
      text: '● BEAT',
      style: TextStyle(
        color: Color.lerp(
          Colors.white.withValues(alpha: 0.2),
          const Color(0xFF55FF88),
          _beatFlash,
        ),
        fontSize: 7,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(finalMeterLeft + finalLabelWidth + 8, finalMeterTop - 10),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          finalMeterLeft,
          finalMeterTop,
          finalMeterWidth,
          finalMeterHeight,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          finalMeterLeft,
          finalMeterTop,
          finalMeterWidth * (finalRatio / 2.0),
          finalMeterHeight,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = finalColor.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill,
    );

    for (final entry in [
      (meanThreshold, const Color(0xFFFF5555), 'MEAN'),
      (emaThreshold, const Color(0xFFFFE66D), 'EMA'),
    ]) {
      final ratio = entry.$1;
      final color = entry.$2;
      final label = entry.$3;
      final lineY = baseY - (ratio / 3.0 * maxH);
      canvas.drawLine(
        Offset(startX - panelPad + 4, lineY),
        Offset(startX + totalW + panelPad - 4, lineY),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1.0,
      );
      _textPainter.text = TextSpan(
        text: '$label ${ratio.toStringAsFixed(2)}x',
        style: TextStyle(
          color: color.withValues(alpha: 0.55),
          fontSize: 7,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(startX - panelPad + 4, lineY - 9));
    }

    for (int i = 0; i < numAlgos; i++) {
      final flash = _algoFlash[i];
      final level = _algoLevel[i].clamp(0.0, 3.0);
      final barLeft = startX + i * (barW + barGap);
      final color = _bandColors[i + 1];
      final isWinning = winningAlgoId == i;

      final levelH = (level / 3.0 * maxH).clamp(2.0, maxH);
      final levelTop = baseY - levelH;
      final levelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, levelTop, barW, levelH),
        const Radius.circular(5),
      );

      canvas.drawRRect(
        levelRect,
        Paint()
          ..shader = Gradient.linear(
            Offset(barLeft, baseY),
            Offset(barLeft, levelTop),
            [color.withValues(alpha: 0.18), color.withValues(alpha: 0.55)],
          )
          ..style = PaintingStyle.fill,
      );

      if (flash > 0.01 && _glowSigma > 0.0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barLeft, baseY - maxH, barW, maxH),
            const Radius.circular(5),
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: flash * 0.45)
            ..style = PaintingStyle.fill
            ..maskFilter = isWasmSafeMode()
                ? null
                : MaskFilter.blur(BlurStyle.normal, _glowSigma),
        );
      }

      canvas.drawRRect(
        levelRect,
        Paint()
          ..color = color.withValues(
            alpha: (isWinning ? 0.65 : 0.35) + flash * 0.30,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = isWinning || flash > 0.1 ? 2.0 : 1.0,
      );

      final lines = _algoLabels[i].split('\n');
      for (int l = 0; l < lines.length; l++) {
        _textPainter.text = TextSpan(
          text: lines[l],
          style: TextStyle(
            color: color.withValues(alpha: 0.55 + flash * 0.45),
            fontSize: l == 0 ? 9 : 7,
            fontWeight: l == 0 ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
            fontFamily: 'RobotoMono',
          ),
        );
        _textPainter.layout();
        _textPainter.paint(
          canvas,
          Offset(barLeft + (barW - _textPainter.width) / 2, baseY + 8 + l * 12),
        );
      }
    }
  }
}
