part of 'steal_banner.dart';

extension _StealBannerRingRender on StealBanner {
  double _logoScaleFactor(StealConfig config) =>
      config.logoScale.clamp(0.1, 1.0) / 0.5;

  double _innerRadius(
    double minDim,
    StealConfig config,
    double beatPulse,
    double pulseScale,
  ) =>
      minDim *
      StealBanner._baseInnerRadiusRatio *
      config.innerRingScale.clamp(0.1, 2.0) *
      _logoScaleFactor(config);

  double _middleRadius(
    double minDim,
    StealConfig config,
    double innerR,
    double pulseScale,
  ) {
    final gap = config.innerToMiddleGap.clamp(0.0, 1.0);
    return innerR +
        minDim *
            (StealBanner._minRingClearance + gap * 0.08) *
            _logoScaleFactor(config);
  }

  double _outerRadius(
    double minDim,
    StealConfig config,
    double middleR,
    double pulseScale,
  ) {
    final gap = config.middleToOuterGap.clamp(0.0, 1.0);
    return middleR +
        minDim *
            (StealBanner._minRingClearance + gap * 0.08) *
            _logoScaleFactor(config);
  }

  double _autoScaleForSpan(double span, double minSpan, double maxSpan) {
    if (span <= 0) return 1.0;
    if (span < minSpan) {
      return (minSpan / span).clamp(1.0, 1.25);
    }
    if (span > maxSpan) {
      return (maxSpan / span).clamp(0.6, 1.0);
    }
    return 1.0;
  }

  double _measureChar(String char) {
    return StealBanner._charWidthCache.putIfAbsent(char, () {
      final painter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            fontFamily: game.config.bannerFont,
            fontSize: StealBanner._defaultFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      return painter.width;
    });
  }

  void _renderRings(
    Canvas canvas,
    Offset center,
    double minDim,
    bool glowEnabled,
    StealConfig config, {
    required double beatPulse,
    required double pulseScale,
  }) {
    final innerR = _innerRadius(minDim, config, beatPulse, pulseScale);
    final middleR = _middleRadius(minDim, config, innerR, pulseScale);
    final outerR = _outerRadius(minDim, config, middleR, pulseScale);

    if (_outerCurrent.isNotEmpty && _outerOpacity > 0.01) {
      _drawRing(
        canvas,
        _outerCurrent,
        _outerWords,
        center,
        outerR,
        _outerAngle,
        _opacity * _outerOpacity,
        glowEnabled,
        config,
        fontScale: config.outerRingFontScale,
        spacingMultiplier: config.outerRingSpacingMultiplier,
        isInner: false,
      );
    }
    if (_middleCurrent.isNotEmpty && _middleOpacity > 0.01) {
      _drawRing(
        canvas,
        _middleCurrent,
        _middleWords,
        center,
        middleR,
        _middleAngle,
        _opacity * _middleOpacity,
        glowEnabled,
        config,
        letterSpacing: config.trackLetterSpacing,
        wordSpacing: config.trackWordSpacing,
        fontScale: config.middleRingFontScale,
        spacingMultiplier: config.middleRingSpacingMultiplier,
        isInner: false,
      );
    }
    if (_innerCurrent.isNotEmpty && _innerOpacity > 0.01) {
      _drawRing(
        canvas,
        _innerCurrent,
        _innerWords,
        center,
        innerR,
        _innerAngle,
        _opacity * _innerOpacity,
        glowEnabled,
        config,
        fontScale: config.innerRingFontScale,
        spacingMultiplier: config.innerRingSpacingMultiplier,
        isInner: true,
      );
    }
  }

  void _drawRing(
    Canvas canvas,
    String text,
    List<_NeonWord> words,
    Offset center,
    double radius,
    double startAngle,
    double effectiveOpacity,
    bool glowEnabled,
    StealConfig config, {
    double fontScale = 1.0,
    double spacingMultiplier = 1.0,
    double? letterSpacing,
    double? wordSpacing,
    bool isInner = false,
  }) {
    if (text.isEmpty) return;

    double lSpace =
        (letterSpacing ?? config.bannerLetterSpacing) * spacingMultiplier;
    double wSpace =
        (wordSpacing ?? config.bannerWordSpacing) * spacingMultiplier;

    if (config.bannerFont.toLowerCase().contains('rock')) {
      lSpace *= 1.08;
      wSpace *= 1.15;
    }

    final wordList = words.isNotEmpty
        ? words
        : text
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map(_NeonWord.new)
              .toList();

    double calcRawSpan(double lSpace, double wSpace) {
      double span = 0.0;
      for (int wi = 0; wi < wordList.length; wi++) {
        for (final char in wordList[wi].text.characters) {
          span += (_measureChar(char) * fontScale * lSpace) / radius;
        }
        if (wi < wordList.length - 1) {
          double currentWSpace = wSpace;
          if (config.bannerFont.toLowerCase().contains('rock') &&
              RegExp(r'^\d').hasMatch(wordList[wi + 1].text)) {
            currentWSpace *= 1.5;
          }
          span +=
              (StealBanner._defaultFontSize * fontScale * currentWSpace) /
              radius;
        }
      }
      return span;
    }

    double currentSpan = calcRawSpan(lSpace, wSpace);

    if (config.autoRingSpacing) {
      final double minAutoSpan = isInner ? (110 / 180) * pi : (165 / 180) * pi;
      final double maxAutoSpan = isInner ? (260 / 180) * pi : (310 / 180) * pi;

      final scale = _autoScaleForSpan(currentSpan, minAutoSpan, maxAutoSpan);
      if (scale != 1.0) {
        lSpace *= scale;
        wSpace *= scale;
        currentSpan = calcRawSpan(lSpace, wSpace);
      }
    }

    const double maxAllowedSpan = (320 / 180) * pi;
    if (currentSpan > maxAllowedSpan) {
      final compressionFactor = maxAllowedSpan / currentSpan;
      lSpace *= max(0.75, compressionFactor);
      wSpace *= compressionFactor;
      currentSpan = calcRawSpan(lSpace, wSpace);
    }

    double angle = startAngle - pi / 2 - currentSpan / 2;
    final centerX = center.dx;
    final centerY = center.dy;
    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;
      final chars = word.text.characters.toList();

      for (int ci = 0; ci < chars.length; ci++) {
        final charWidth = _measureChar(chars[ci]) * fontScale * lSpace;
        final charAngle = charWidth / radius;
        final centerAngle = angle + charAngle / 2;

        final charX = centerX + radius * cos(centerAngle);
        final charY = centerY + radius * sin(centerAngle);

        canvas.save();
        canvas.translate(charX, charY);
        canvas.rotate(centerAngle + pi / 2);

        if (fontScale != 1.0) canvas.scale(fontScale);

        final opacity = effectiveOpacity * wordBrightness;

        _paintChar(
          canvas,
          chars[ci],
          _measureChar(chars[ci]) * lSpace,
          _currentColor,
          opacity,
          glowEnabled,
          config,
        );

        canvas.restore();
        angle += charAngle;
      }

      if (wi < wordList.length - 1) {
        double currentWSpace = wSpace;
        if (config.bannerFont.toLowerCase().contains('rock') &&
            RegExp(r'^\d').hasMatch(wordList[wi + 1].text)) {
          currentWSpace *= 1.5;
        }
        angle +=
            (StealBanner._defaultFontSize * fontScale * currentWSpace) / radius;
      }
    }
  }

  void _paintChar(
    ui.Canvas canvas,
    String char,
    double width,
    Color color,
    double opacity,
    bool glowEnabled,
    StealConfig config,
  ) {
    if (opacity <= 0.0) return;

    final blurAmount = config.blurAmount.clamp(0.0, 1.0) * 12.0;
    final resolution = config.bannerResolution.clamp(1.0, 4.0);

    if (StealBanner._lastGlowBlur != blurAmount ||
        StealBanner._lastGlowEnabled != glowEnabled ||
        StealBanner._lastFontFamily != config.bannerFont ||
        StealBanner._lastResolution != resolution) {
      StealBanner._glyphCache.clear();
      StealBanner._lastGlowBlur = blurAmount;
      StealBanner._lastGlowEnabled = glowEnabled;
      StealBanner._lastFontFamily = config.bannerFont;
      StealBanner._lastResolution = resolution;
    }

    final glyph = StealBanner._glyphCache.putIfAbsent(
      char,
      () => _rasterizeChar(char, config),
    );

    final paint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: opacity),
        BlendMode.modulate,
      )
      ..filterQuality = ui.FilterQuality.medium
      ..isAntiAlias = true;

    final rs = config.bannerResolution.clamp(1.0, 4.0);
    if (rs != 1.0) {
      canvas.save();
      canvas.scale(1.0 / rs);
    }

    canvas.drawImage(
      glyph.image,
      Offset(
        (-glyph.coreWidth / 2 - glyph.padding),
        (-glyph.coreHeight / 2 - glyph.padding),
      ),
      paint,
    );

    if (rs != 1.0) canvas.restore();
  }

  _RasterGlyph _rasterizeChar(String char, StealConfig config) {
    final res = config.bannerResolution.clamp(1.0, 4.0);
    final fontSize = StealBanner._defaultFontSize * res;
    final blurAmount = config.blurAmount.clamp(0.0, 1.0) * 12.0 * res;

    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontFamily: FontConfig.resolve(config.bannerFont),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final cw = painter.width;
    final ch = painter.height;
    final padding = blurAmount * 2.5 + 4.0 * res;
    final iw = (cw + padding * 2).ceil();
    final ih = (ch + padding * 2).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (config.bannerGlow) {
      final glowPaint = Paint()
        ..maskFilter = isWasmSafeMode()
            ? null
            : MaskFilter.blur(BlurStyle.normal, blurAmount);
      canvas.saveLayer(null, glowPaint);
      canvas.translate(padding, padding);
      painter.paint(canvas, Offset.zero);
      canvas.restore();

      final coreGlowPaint = Paint()
        ..maskFilter = isWasmSafeMode()
            ? null
            : MaskFilter.blur(BlurStyle.normal, blurAmount * 0.3);
      canvas.saveLayer(null, coreGlowPaint);
      canvas.translate(padding, padding);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    canvas.save();
    canvas.translate(padding, padding);
    painter.paint(canvas, Offset.zero);
    canvas.restore();

    final picture = recorder.endRecording();
    final image = picture.toImageSync(iw, ih);

    return _RasterGlyph(
      image: image,
      coreWidth: cw,
      coreHeight: ch,
      padding: padding,
    );
  }
}
