part of 'steal_banner.dart';

extension _StealBannerFlatRender on StealBanner {
  void _renderFlat(
    Canvas canvas,
    Offset center,
    double minDim,
    bool glowEnabled,
    StealConfig config, {
    required double beatPulse,
    required double pulseScale,
  }) {
    // Line order: title, venue, date
    final lines = [
      (_middleCurrent, _middleWords, _middleOpacity), // track title
      (_outerCurrent, _outerWords, _outerOpacity), // venue
      (_innerCurrent, _innerWords, _innerOpacity), // date
    ];

    final isAbove = config.flatTextPlacement == 'above';
    // Use text presence (not opacity) so block height stays stable while lines
    // cross-fade. Gating on opacity caused the venue/date lines to jump
    // position whenever the track title crossed the 0.01 threshold.
    final visibleCount = lines.where((l) => l.$1.isNotEmpty).length;
    final baseLineHeight = StealBanner._flatLineHeight * config.flatLineSpacing;
    double lineHeight = baseLineHeight;
    if (config.autoTextSpacing && visibleCount > 0) {
      final baseBlockHeight = visibleCount * baseLineHeight;
      final minBlockHeight = minDim * 0.14;
      final maxBlockHeight = minDim * 0.30;
      if (baseBlockHeight > maxBlockHeight) {
        lineHeight =
            baseLineHeight *
            (maxBlockHeight / baseBlockHeight).clamp(0.65, 1.0);
      } else if (baseBlockHeight < minBlockHeight) {
        lineHeight =
            baseLineHeight *
            (minBlockHeight / baseBlockHeight).clamp(1.0, 1.25);
      }
    }
    final blockHeight = visibleCount * lineHeight;
    final maxLineWidth = minDim * 0.88;
    final minLineWidth = minDim * 0.38;

    final logoRadius = minDim * 0.5 * config.logoScale.clamp(0.1, 1.0);
    final baseGap = logoRadius * 0.51;
    final proximity = config.flatTextProximity.clamp(0.0, 1.0);
    final basePulse = beatPulse * 0.08;
    final audioShiftScale = pulseScale * (1.0 + basePulse / config.logoScale);

    final centerY = center.dy;
    double blockCenterY;

    if (proximity <= 0.5) {
      final t = proximity / 0.5;
      final currentOffset = baseGap * (2.0 - t) * audioShiftScale;
      if (isAbove) {
        blockCenterY = centerY - currentOffset - blockHeight / 2;
      } else {
        blockCenterY = centerY + currentOffset + blockHeight / 2;
      }
    } else {
      final t = (proximity - 0.5) / 0.5;
      final lerpBaseOffset = (baseGap + blockHeight / 2) * audioShiftScale;
      if (isAbove) {
        blockCenterY = ui.lerpDouble(centerY - lerpBaseOffset, centerY, t)!;
      } else {
        blockCenterY = ui.lerpDouble(centerY + lerpBaseOffset, centerY, t)!;
      }
    }

    if (config.bannerPixelSnap) {
      blockCenterY = blockCenterY.roundToDouble();
    }

    final startY = blockCenterY - (blockHeight / 2) + (lineHeight / 2);

    int slotIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].$1;
      final words = lines[i].$2;
      final lineOpacity = lines[i].$3;

      if (text.isEmpty) continue;

      final effectiveOpacity = _opacity * lineOpacity;

      if (effectiveOpacity > 0.001) {
        final lineCenter = Offset(center.dx, startY + slotIndex * lineHeight);

        _drawFlatLine(
          canvas,
          text,
          words,
          lineCenter,
          effectiveOpacity,
          glowEnabled,
          config,
          letterSpacing: (i == 0)
              ? config.trackLetterSpacing
              : config.bannerLetterSpacing,
          wordSpacing: (i == 0)
              ? config.trackWordSpacing
              : config.bannerWordSpacing,
          minLineWidth: minLineWidth,
          maxLineWidth: maxLineWidth,
        );
      }
      slotIndex++;
    }
  }

  double _autoScaleForWidth(double width, double minWidth, double maxWidth) {
    if (width <= 0) return 1.0;
    if (width < minWidth) {
      return (minWidth / width).clamp(1.0, 1.25);
    }
    if (width > maxWidth) {
      return (maxWidth / width).clamp(0.6, 1.0);
    }
    return 1.0;
  }

  double _measureWordListWidth(
    List<_NeonWord> wordList,
    double letterSpacing,
    double wordSpacing,
    StealConfig config,
  ) {
    double totalWidth = 0.0;
    for (int wi = 0; wi < wordList.length; wi++) {
      final text = wordList[wi].text;
      for (final char in text.characters) {
        totalWidth += _measureChar(char) * letterSpacing;
      }
      if (wi < wordList.length - 1) {
        double currentWSpace = wordSpacing;
        if (config.bannerFont.toLowerCase().contains('rock') &&
            RegExp(r'^\d').hasMatch(wordList[wi + 1].text)) {
          currentWSpace *= 1.5;
        }
        totalWidth += StealBanner._defaultFontSize * currentWSpace;
      }
    }
    return totalWidth;
  }

  void _drawFlatLine(
    Canvas canvas,
    String text,
    List<_NeonWord> words,
    Offset center,
    double effectiveOpacity,
    bool glowEnabled,
    StealConfig config, {
    double? letterSpacing,
    double? wordSpacing,
    required double minLineWidth,
    required double maxLineWidth,
  }) {
    if (text.isEmpty) return;

    final wordList = words.isNotEmpty
        ? words
        : text
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map(_NeonWord.new)
              .toList();

    var lSpace = letterSpacing ?? config.bannerLetterSpacing;
    var wSpace = wordSpacing ?? config.bannerWordSpacing;

    if (config.bannerFont.toLowerCase().contains('rock')) {
      lSpace *= 1.08;
      wSpace *= 1.15;
    }

    double totalWidth = _measureWordListWidth(wordList, lSpace, wSpace, config);

    if (config.autoTextSpacing) {
      final scale = _autoScaleForWidth(totalWidth, minLineWidth, maxLineWidth);
      if (scale != 1.0) {
        lSpace *= scale;
        wSpace *= scale;
        totalWidth = _measureWordListWidth(wordList, lSpace, wSpace, config);
      }

      if (totalWidth > maxLineWidth) {
        final compressionFactor = maxLineWidth / totalWidth;
        lSpace *= max(0.8, compressionFactor);
        wSpace *= compressionFactor;
        totalWidth = _measureWordListWidth(wordList, lSpace, wSpace, config);
      }
    }

    double x = center.dx - totalWidth / 2;
    double y = center.dy;

    if (config.bannerPixelSnap) {
      x = x.roundToDouble();
      y = y.roundToDouble();
    }

    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;

      for (final char in word.text.characters) {
        final charWidth = _measureChar(char) * lSpace;

        canvas.save();
        canvas.translate(x + charWidth / 2, y);

        final opacity = effectiveOpacity * wordBrightness;

        _paintChar(
          canvas,
          char,
          charWidth,
          _currentColor,
          opacity,
          glowEnabled,
          config,
        );

        canvas.restore();
        x += charWidth;
      }

      if (wi < wordList.length - 1) {
        double currentWSpace = wSpace;
        if (config.bannerFont.toLowerCase().contains('rock') &&
            RegExp(r'^\d').hasMatch(wordList[wi + 1].text)) {
          currentWSpace *= 1.5;
        }
        x += StealBanner._defaultFontSize * currentWSpace;
      }
    }
  }
}
