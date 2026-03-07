import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders track info in one of two modes:
///
/// Ring mode (bannerDisplayMode == 'ring'):
///   Three circular rotating text rings orbiting the Steal Your Face logo.
///   Outer ring: venue — clockwise, fastest
///   Middle ring: track title — clockwise, medium
///   Inner ring: date — clockwise, slowest
///
/// Flat mode (bannerDisplayMode == 'flat'):
///   Three stacked lines centered below the logo:
///   Line 1: track title
///   Line 2: venue
///   Line 3: date
///
/// Both modes support neon glow and per-word flicker when bannerGlow is on.

// ── Neon flicker per-word state ────────────────────────────────────────────

enum _FlickerPhase { idle, buzz, dropout, recover }

class _NeonWord {
  final String text;
  double brightness = 1.0;
  double target = 1.0;
  double eventTimer = 0.0;
  _FlickerPhase phase = _FlickerPhase.idle;
  double buzzFreq = 0.0;
  double buzzAmp = 0.0;

  _NeonWord(this.text);
}

class _RasterGlyph {
  final ui.Image image;
  final double coreWidth;
  final double coreHeight;
  final double padding;

  _RasterGlyph({
    required this.image,
    required this.coreWidth,
    required this.coreHeight,
    required this.padding,
  });
}

// ── Main component ─────────────────────────────────────────────────────────

class StealBanner extends Component with HasGameReference<StealGame> {
  // ── Rotation ───────────────────────────────────────────────────────────────
  static const double _baseRotationSpeed = 0.0006;

  // ── Base inner radius ──────────────────────────────────────────────────────
  static const double _baseInnerRadiusRatio = 0.110;

  // ── Minimum ring clearance at gap=0 ───────────────────────────────────────
  static const double _minRingClearance = 0.018;

  // ── Ring mode: default base spacing ───────────────────────────────────────
  static const double _defaultFontSize = 11.0;

  // ── Flat mode layout ───────────────────────────────────────────────────────
  // Line height in pixels. Gap is computed dynamically in _renderFlat.
  static const double _flatLineHeight = 16.0;

  // ── Fade ───────────────────────────────────────────────────────────────────
  static const double _fadeSpeed = 0.6;
  static const double _ringFadeSpeed = 1.2;

  // ── Char width cache (static — shared across instances) ───────────────────
  static final Map<String, double> _charWidthCache = {};

  // ── Rasterized glyph cache ─────────────────────────────────────────────────
  static final Map<String, _RasterGlyph> _glyphCache = {};
  static double _lastGlowBlur = -1.0;
  static bool _lastGlowEnabled = false;
  static String? _lastFontFamily;
  static double _lastResolution = -1.0;

  // ── Per-ring state ─────────────────────────────────────────────────────────
  String _outerCurrent = '';
  String _outerPending = '';
  double _outerOpacity = 0.0;
  bool _outerFadingOut = false;
  double _outerAngle = 0.0;
  List<_NeonWord> _outerWords = [];

  String _middleCurrent = '';
  String _middlePending = '';
  double _middleOpacity = 0.0;
  bool _middleFadingOut = false;
  double _middleAngle = 0.0;
  List<_NeonWord> _middleWords = [];

  String _innerCurrent = '';
  String _innerPending = '';
  double _innerOpacity = 0.0;
  bool _innerFadingOut = false;
  double _innerAngle = 0.0;
  List<_NeonWord> _innerWords = [];

  // ── Shared ─────────────────────────────────────────────────────────────────
  Color _color = Colors.white;
  Color _currentColor = Colors.white;
  bool _visible = false;
  double _opacity = 0.0;

  final _rng = Random();

  // ── Public API ─────────────────────────────────────────────────────────────

  void updateBanner(
    String trackTitle,
    Color color, {
    bool showBanner = true,
    String venue = '',
    String date = '',
  }) {
    _color = color;
    _visible = showBanner &&
        (trackTitle.isNotEmpty || venue.isNotEmpty || date.isNotEmpty);

    if (_currentColor == Colors.white && _opacity == 0.0) {
      _currentColor = color;
    }

    _queueRingUpdate(
      newText: venue,
      current: _outerCurrent,
      opacity: _outerOpacity,
      setCurrent: (v) {
        _outerCurrent = v;
      },
      setPending: (v) {
        _outerPending = v;
      },
      setFadingOut: (v) {
        _outerFadingOut = v;
      },
      setWords: (v) {
        _outerWords = v;
      },
    );
    _queueRingUpdate(
      newText: trackTitle,
      current: _middleCurrent,
      opacity: _middleOpacity,
      setCurrent: (v) {
        _middleCurrent = v;
      },
      setPending: (v) {
        _middlePending = v;
      },
      setFadingOut: (v) {
        _middleFadingOut = v;
      },
      setWords: (v) {
        _middleWords = v;
      },
    );
    _queueRingUpdate(
      newText: AppDateUtils.formatDate(date),
      current: _innerCurrent,
      opacity: _innerOpacity,
      setCurrent: (v) {
        _innerCurrent = v;
      },
      setPending: (v) {
        _innerPending = v;
      },
      setFadingOut: (v) {
        _innerFadingOut = v;
      },
      setWords: (v) {
        _innerWords = v;
      },
    );
  }

  void _queueRingUpdate({
    required String newText,
    required String current,
    required double opacity,
    required void Function(String) setCurrent,
    required void Function(String) setPending,
    required void Function(bool) setFadingOut,
    required void Function(List<_NeonWord>) setWords,
  }) {
    if (newText == current) return;
    if (opacity <= 0.05 || current.isEmpty) {
      setCurrent(newText);
      setFadingOut(false);
      setWords(_buildWords(newText));
    } else {
      setPending(newText);
      setFadingOut(true);
    }
  }

  List<_NeonWord> _buildWords(String text) {
    if (text.isEmpty) return [];
    final parts = text.split(' ').where((w) => w.isNotEmpty).toList();
    return parts.map((w) {
      final word = _NeonWord(w);
      word.eventTimer = _rng.nextDouble() * 3.0;
      return word;
    }).toList();
  }

  // ── Flame update ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    _currentColor = Color.lerp(_currentColor, _color, 0.025)!;

    final StealConfig config = game.config;
    final minDim = min(game.size.x, game.size.y);
    final innerR = _innerRadius(minDim, config);
    final middleR = _middleRadius(minDim, config, innerR);
    final outerR = _outerRadius(minDim, config, middleR);

    if (_visible) {
      _innerAngle += _baseRotationSpeed * innerR * dt;
      _middleAngle += _baseRotationSpeed * middleR * dt;
      _outerAngle += _baseRotationSpeed * outerR * dt;
      if (_innerAngle > 2 * pi) _innerAngle -= 2 * pi;
      if (_middleAngle > 2 * pi) _middleAngle -= 2 * pi;
      if (_outerAngle > 2 * pi) _outerAngle -= 2 * pi;
      _opacity = (_opacity + _fadeSpeed * dt).clamp(0.0, 1.0);
    } else {
      _opacity = (_opacity - _fadeSpeed * dt).clamp(0.0, 1.0);
    }

    _tickFade(dt, _outerFadingOut, _outerOpacity, _outerPending, (v) {
      _outerOpacity = v;
    }, (v) {
      _outerCurrent = v;
    }, (v) {
      _outerPending = v;
    }, (v) {
      _outerFadingOut = v;
    }, (v) {
      _outerWords = v;
    });
    _tickFade(dt, _middleFadingOut, _middleOpacity, _middlePending, (v) {
      _middleOpacity = v;
    }, (v) {
      _middleCurrent = v;
    }, (v) {
      _middlePending = v;
    }, (v) {
      _middleFadingOut = v;
    }, (v) {
      _middleWords = v;
    });
    _tickFade(dt, _innerFadingOut, _innerOpacity, _innerPending, (v) {
      _innerOpacity = v;
    }, (v) {
      _innerCurrent = v;
    }, (v) {
      _innerPending = v;
    }, (v) {
      _innerFadingOut = v;
    }, (v) {
      _innerWords = v;
    });

    if (config.bannerGlow && config.bannerFlicker > 0.0) {
      final strength = config.bannerFlicker.clamp(0.0, 1.0);
      for (final words in [_outerWords, _middleWords, _innerWords]) {
        for (final word in words) {
          _tickWordFlicker(word, dt, strength);
        }
      }
    } else {
      for (final words in [_outerWords, _middleWords, _innerWords]) {
        for (final word in words) {
          word.brightness = 1.0;
        }
      }
    }
  }

  void _tickFade(
    double dt,
    bool fadingOut,
    double opacity,
    String pending,
    void Function(double) setOpacity,
    void Function(String) setCurrent,
    void Function(String) setPending,
    void Function(bool) setFadingOut,
    void Function(List<_NeonWord>) setWords,
  ) {
    if (fadingOut) {
      final next = (opacity - _ringFadeSpeed * dt).clamp(0.0, 1.0);
      setOpacity(next);
      if (next <= 0.0) {
        setCurrent(pending);
        setPending('');
        setFadingOut(false);
        setWords(_buildWords(pending));
      }
    } else {
      if (_visible) {
        setOpacity((opacity + _ringFadeSpeed * dt).clamp(0.0, 1.0));
      } else {
        setOpacity((opacity - _ringFadeSpeed * dt).clamp(0.0, 1.0));
      }
    }
  }

  // ── Per-word neon flicker phase machine ────────────────────────────────────

  void _tickWordFlicker(_NeonWord word, double dt, double strength) {
    word.eventTimer -= dt;

    switch (word.phase) {
      case _FlickerPhase.idle:
        // At low strength jitter is imperceptible — brightness stays near 1.0
        final jitterAmp = strength * strength * 0.03;
        final jitter = jitterAmp * (_rng.nextDouble() * 2 - 1);
        word.brightness =
            (word.brightness + (1.0 + jitter - word.brightness) * 4.0 * dt)
                .clamp(0.93, 1.0);

        if (word.eventTimer <= 0.0) {
          final doBuzz = _rng.nextDouble() < 0.65;
          if (doBuzz) {
            word.phase = _FlickerPhase.buzz;
            word.eventTimer =
                ui.lerpDouble(0.20, 0.06, strength)! + _rng.nextDouble() * 0.14;
            word.buzzFreq = 15.0 + _rng.nextDouble() * 10.0;
            word.buzzAmp = ui.lerpDouble(0.04, 0.18, strength)!;
          } else {
            word.phase = _FlickerPhase.dropout;
            word.eventTimer = 0.025 + _rng.nextDouble() * 0.035;
            // Brightness floor scales with strength — barely a dip at low values
            final minFloor = ui.lerpDouble(0.88, 0.08, strength)!;
            word.target =
                minFloor + _rng.nextDouble() * (1.0 - minFloor) * 0.15;
          }
        }

      case _FlickerPhase.buzz:
        final osc = sin(word.buzzFreq * 2 * pi * (1.0 - word.eventTimer));
        // Sine envelope fades buzz in/out — no hard start or end
        final buzzProgress =
            (1.0 - (word.eventTimer / (word.buzzAmp * 4.0))).clamp(0.0, 1.0);
        final envelope = sin(buzzProgress * pi).clamp(0.0, 1.0);
        word.brightness =
            (1.0 + osc * word.buzzAmp * envelope).clamp(0.82, 1.0);
        if (word.eventTimer <= 0.0) {
          // Ease back rather than snap
          word.brightness =
              (word.brightness + (1.0 - word.brightness) * 0.4).clamp(0.9, 1.0);
          word.phase = _FlickerPhase.idle;
          word.eventTimer = _nextIdleTime(strength);
        }

      case _FlickerPhase.dropout:
        // Slow lerp into dip — no hard snap
        word.brightness += (word.target - word.brightness) * 6.0 * dt;
        if (word.eventTimer <= 0.0) {
          word.phase = _FlickerPhase.recover;
          word.eventTimer = 0.06 + _rng.nextDouble() * 0.10;
        }

      case _FlickerPhase.recover:
        // Gentle ease back to full brightness
        word.brightness += (1.0 - word.brightness) * 5.0 * dt;
        if (word.eventTimer <= 0.0) {
          // Only exit when close enough — no snap-to-1.0
          if (word.brightness > 0.92) {
            word.brightness = 1.0;
            word.phase = _FlickerPhase.idle;
            word.eventTimer = _nextIdleTime(strength);
          } else {
            word.eventTimer = 0.04; // extend recover
          }
        }
    }
  }

  double _nextIdleTime(double strength) {
    final minIdle = ui.lerpDouble(2.0, 0.3, strength)!;
    final maxIdle = ui.lerpDouble(6.0, 1.2, strength)!;
    return minIdle + _rng.nextDouble() * (maxIdle - minIdle);
  }

  // ── Radius helpers ─────────────────────────────────────────────────────────
  //
  // Rings scale relative to logoScale so they always orbit proportionally
  // to the rendered logo size. logoScale=0.5 (the default) is the neutral
  // point — at that scale the rings sit exactly as designed by the gap settings.
  // Doubling logoScale doubles ring radii; halving it halves them.

  double _logoScaleFactor(StealConfig config) =>
      config.logoScale.clamp(0.1, 1.0) / 0.5; // 1.0 at default logoScale=0.5

  double _innerRadius(double minDim, StealConfig config) =>
      minDim *
      _baseInnerRadiusRatio *
      config.innerRingScale.clamp(0.1, 2.0) *
      _logoScaleFactor(config);

  double _middleRadius(double minDim, StealConfig config, double innerR) {
    final gap = config.innerToMiddleGap.clamp(0.0, 1.0);
    return innerR +
        minDim * (_minRingClearance + gap * 0.08) * _logoScaleFactor(config);
  }

  double _outerRadius(double minDim, StealConfig config, double middleR) {
    final gap = config.middleToOuterGap.clamp(0.0, 1.0);
    return middleR +
        minDim * (_minRingClearance + gap * 0.08) * _logoScaleFactor(config);
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) return;

    final StealConfig config = game.config;
    final logoPos = game.smoothedLogoPos;
    final center = Offset(logoPos.dx * w, logoPos.dy * h);
    final minDim = min(w, h);
    final glowEnabled = config.bannerGlow;
    final isFlat = config.bannerDisplayMode == 'flat';

    if (isFlat) {
      _renderFlat(canvas, center, minDim, glowEnabled, config);
    } else {
      _renderRings(canvas, center, minDim, glowEnabled, config);
    }
  }

  // ── Flat render ────────────────────────────────────────────────────────────

  void _renderFlat(
    Canvas canvas,
    Offset center,
    double minDim,
    bool glowEnabled,
    StealConfig config,
  ) {
    // Line order: title, venue, date
    final lines = [
      (_middleCurrent, _middleWords, _middleOpacity), // track title
      (_outerCurrent, _outerWords, _outerOpacity), // venue
      (_innerCurrent, _innerWords, _innerOpacity), // date
    ];

    final isAbove = config.flatTextPlacement == 'above';
    final visibleCount =
        lines.where((l) => l.$1.isNotEmpty && l.$3 > 0.01).length;
    final lineHeight = _flatLineHeight * config.flatLineSpacing;
    final blockHeight = visibleCount * lineHeight;

    // Proximity 0.0: Full gap (Away)
    // Proximity 0.5: No gap (Edge - resting on visual bounds)
    // Proximity 1.0: Center (Centered vertically on the logo)
    final logoRadius = minDim * 0.5 * config.logoScale.clamp(0.1, 1.0);
    // 0.51 multiplier for a tighter "No Gap" look than the previous 0.55
    final baseGap = logoRadius * 0.51;
    final proximity = config.flatTextProximity.clamp(0.0, 1.0);

    final centerY = center.dy;
    final double blockCenterY;

    if (proximity <= 0.5) {
      // Transition from Away (2*baseGap) to Edge (1*baseGap)
      final t = proximity / 0.5;
      final currentOffset = baseGap * (2.0 - t);
      if (isAbove) {
        blockCenterY = centerY - currentOffset - blockHeight / 2;
      } else {
        blockCenterY = centerY + currentOffset + blockHeight / 2;
      }
    } else {
      // Transition from Edge (baseGap) to Centered (0 offset)
      final t = (proximity - 0.5) / 0.5;
      if (isAbove) {
        // As proximity goes 0.5 -> 1.0, block center goes from
        // [centerY - baseGap - blockHeight/2] up to [centerY]
        blockCenterY =
            ui.lerpDouble(centerY - baseGap - blockHeight / 2, centerY, t)!;
      } else {
        // As proximity goes 0.5 -> 1.0, block center goes from
        // [centerY + baseGap + blockHeight/2] down to [centerY]
        blockCenterY =
            ui.lerpDouble(centerY + baseGap + blockHeight / 2, centerY, t)!;
      }
    }

    final startY = blockCenterY - (blockHeight / 2) + (lineHeight / 2);

    int visibleIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].$1;
      final words = lines[i].$2;
      final lineOpacity = lines[i].$3;

      if (text.isEmpty || lineOpacity <= 0.01) continue;

      final effectiveOpacity = _opacity * lineOpacity;

      final lineCenter = Offset(
        center.dx,
        startY + visibleIndex * lineHeight,
      );

      _drawFlatLine(
        canvas,
        text,
        words,
        lineCenter,
        effectiveOpacity,
        glowEnabled,
        config,
        letterSpacing:
            (i == 0) ? config.trackLetterSpacing : config.bannerLetterSpacing,
        wordSpacing:
            (i == 0) ? config.trackWordSpacing : config.bannerWordSpacing,
      );
      visibleIndex++;
    }
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
  }) {
    if (text.isEmpty) return;

    final wordList = words.isNotEmpty
        ? words
        : text
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map(_NeonWord.new)
            .toList();

    final lSpace = letterSpacing ?? config.bannerLetterSpacing;
    final wSpace = wordSpacing ?? config.bannerWordSpacing;

    // Measure total width including letter and word spacing
    double totalWidth = 0.0;
    for (int wi = 0; wi < wordList.length; wi++) {
      final text = wordList[wi].text;
      for (final char in text.characters) {
        totalWidth += _measureChar(char) * lSpace;
      }
      if (wi < wordList.length - 1) {
        totalWidth += _defaultFontSize * wSpace;
      }
    }

    double x = center.dx - totalWidth / 2;

    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;

      for (final char in word.text.characters) {
        final charWidth = _measureChar(char) * lSpace;

        double charX = x + charWidth / 2;
        double charY = center.dy;

        if (config.bannerPixelSnap) {
          charX = charX.roundToDouble();
          charY = charY.roundToDouble();
        }

        canvas.save();
        canvas.translate(charX, charY);

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
        x += _defaultFontSize * wSpace;
      }
    }
  }

  // ── Char width cache ───────────────────────────────────────────────────────

  double _measureChar(String char) {
    return _charWidthCache.putIfAbsent(char, () {
      final painter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            fontFamily: game.config.bannerFont,
            fontSize: _defaultFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      return painter.width;
    });
  }

  // ── Ring render ────────────────────────────────────────────────────────────

  void _renderRings(
    Canvas canvas,
    Offset center,
    double minDim,
    bool glowEnabled,
    StealConfig config,
  ) {
    final innerR = _innerRadius(minDim, config);
    final middleR = _middleRadius(minDim, config, innerR);
    final outerR = _outerRadius(minDim, config, middleR);

    if (_outerCurrent.isNotEmpty && _outerOpacity > 0.01) {
      _drawRing(canvas, _outerCurrent, _outerWords, center, outerR, _outerAngle,
          _opacity * _outerOpacity, glowEnabled, config);
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
  }) {
    if (text.isEmpty) return;

    // Use user-defined spacing from config (or track override),modulated by per-ring multiplier
    double lSpace =
        (letterSpacing ?? config.bannerLetterSpacing) * spacingMultiplier;
    double wSpace =
        (wordSpacing ?? config.bannerWordSpacing) * spacingMultiplier;

    final wordList = words.isNotEmpty
        ? words
        : text
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map(_NeonWord.new)
            .toList();

    // 1. Calculate the raw span required with current settings
    double calcRawSpan(double lSpace, double wSpace) {
      double span = 0.0;
      for (int wi = 0; wi < wordList.length; wi++) {
        for (final char in wordList[wi].text.characters) {
          span += (_measureChar(char) * fontScale * lSpace) / radius;
        }
        if (wi < wordList.length - 1) {
          span += (_defaultFontSize * fontScale * wSpace) / radius;
        }
      }
      return span;
    }

    double currentSpan = calcRawSpan(lSpace, wSpace);

    // 2. Dynamic Compression ("Squish-to-fit")
    // If text exceeds ~320 degrees, we compress it to fit.
    const double maxAllowedSpan = (320 / 180) * pi;
    if (currentSpan > maxAllowedSpan) {
      final compressionFactor = maxAllowedSpan / currentSpan;
      // We don't want to squish letters too much (min 0.8x original),
      // but words can squish more aggressively.
      lSpace *= max(0.85, compressionFactor);
      wSpace *= compressionFactor;
      currentSpan = calcRawSpan(lSpace, wSpace);
    }

    double angle = startAngle - pi / 2 - currentSpan / 2;

    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;
      final chars = word.text.characters.toList();

      for (int ci = 0; ci < chars.length; ci++) {
        final charWidth = _measureChar(chars[ci]) * fontScale * lSpace;
        final charAngle = charWidth / radius;

        final centerAngle = angle + charAngle / 2;

        double charX = center.dx + radius * cos(centerAngle);
        double charY = center.dy + radius * sin(centerAngle);

        if (config.bannerPixelSnap) {
          charX = charX.roundToDouble();
          charY = charY.roundToDouble();
        }

        canvas.save();
        canvas.translate(charX, charY);
        canvas.rotate(centerAngle + pi / 2);

        // Apply font scaling via canvas transform so rasterized glyphs
        // are drawn smaller without re-rasterizing.
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
        angle += (_defaultFontSize * fontScale * wSpace) / radius;
      }
    }
  }

  // ── Paint Char ─────────────────────────────────────────────────────────────

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

    // Check if we need to clear glyph cache (font or glow param changed)
    if (_lastGlowBlur != blurAmount ||
        _lastGlowEnabled != glowEnabled ||
        _lastFontFamily != config.bannerFont ||
        _lastResolution != resolution) {
      _glyphCache.clear();
      _lastGlowBlur = blurAmount;
      _lastGlowEnabled = glowEnabled;
      _lastFontFamily = config.bannerFont;
      _lastResolution = resolution;
    }

    final glyph =
        _glyphCache.putIfAbsent(char, () => _rasterizeChar(char, config));

    final paint = Paint()
      ..colorFilter =
          ColorFilter.mode(color.withValues(alpha: opacity), BlendMode.modulate)
      ..isAntiAlias = true;

    // Draw the rasterized image.
    // The image has padding for the glow, so we center it.
    // Scale back down if we rasterized at higher resolution
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
    final fontSize = _defaultFontSize * res;
    final blurAmount = config.blurAmount.clamp(0.0, 1.0) * 12.0 * res;

    // Measure core size
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontFamily: config.bannerFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final cw = painter.width;
    final ch = painter.height;

    // Add padding for the neon glow blur
    final padding = blurAmount * 2.5 + 4.0 * res;
    final iw = (cw + padding * 2).ceil();
    final ih = (ch + padding * 2).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (config.bannerGlow) {
      // Outer glow: wide blur
      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount);
      canvas.saveLayer(null, glowPaint);
      canvas.translate(padding, padding);
      painter.paint(canvas, Offset.zero);
      canvas.restore();

      // Inner glow: tighter blur for core intensity
      final coreGlowPaint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount * 0.3);
      canvas.saveLayer(null, coreGlowPaint);
      canvas.translate(padding, padding);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Draw pure white core
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
