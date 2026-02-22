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
///   Line 1: venue
///   Line 2: track title
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

// ── Main component ─────────────────────────────────────────────────────────

class StealBanner extends Component with HasGameReference<StealGame> {
  // ── Rotation ───────────────────────────────────────────────────────────────
  static const double _baseRotationSpeed = 0.0006;

  // ── Base inner radius ──────────────────────────────────────────────────────
  static const double _baseInnerRadiusRatio = 0.110;

  // ── Minimum ring clearance at gap=0 ───────────────────────────────────────
  static const double _minRingClearance = 0.018;

  // ── Font & letter spacing ──────────────────────────────────────────────────
  static const double _fontSize = 11.0;
  static const double _letterSpacingBoost = 1.08;
  static const double _wordSpacingExtra = 0.8;

  // ── Flat mode layout ───────────────────────────────────────────────────────
  // Vertical offset below logo center as a fraction of minDim
  static const double _flatOffsetRatio = 0.18;
  // Line height in pixels
  static const double _flatLineHeight = 16.0;

  // ── Fade ───────────────────────────────────────────────────────────────────
  static const double _fadeSpeed = 0.6;
  static const double _ringFadeSpeed = 1.2;

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
        final jitter = (strength * 0.03) * (_rng.nextDouble() * 2 - 1);
        word.brightness =
            (word.brightness + (1.0 + jitter - word.brightness) * 8.0 * dt)
                .clamp(0.85, 1.0);

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
            word.target = ui.lerpDouble(0.55, 0.08, strength)!;
          }
        }

      case _FlickerPhase.buzz:
        final osc = sin(word.buzzFreq * 2 * pi * (1.0 - word.eventTimer));
        word.brightness = (1.0 + osc * word.buzzAmp).clamp(0.7, 1.0);
        if (word.eventTimer <= 0.0) {
          word.brightness = 1.0;
          word.phase = _FlickerPhase.idle;
          word.eventTimer = _nextIdleTime(strength);
        }

      case _FlickerPhase.dropout:
        word.brightness += (word.target - word.brightness) * 20.0 * dt;
        if (word.eventTimer <= 0.0) {
          word.phase = _FlickerPhase.recover;
          word.eventTimer = 0.04 + _rng.nextDouble() * 0.08;
        }

      case _FlickerPhase.recover:
        word.brightness += (1.0 - word.brightness) * 12.0 * dt;
        if (word.eventTimer <= 0.0) {
          word.brightness = 1.0;
          word.phase = _FlickerPhase.idle;
          word.eventTimer = _nextIdleTime(strength);
        }
    }
  }

  double _nextIdleTime(double strength) {
    final minIdle = ui.lerpDouble(2.0, 0.3, strength)!;
    final maxIdle = ui.lerpDouble(6.0, 1.2, strength)!;
    return minIdle + _rng.nextDouble() * (maxIdle - minIdle);
  }

  // ── Radius helpers ─────────────────────────────────────────────────────────

  double _innerRadius(double minDim, StealConfig config) =>
      minDim * _baseInnerRadiusRatio * config.innerRingScale.clamp(0.5, 2.0);

  double _middleRadius(double minDim, StealConfig config, double innerR) {
    final gap = config.innerToMiddleGap.clamp(0.0, 1.0);
    return innerR + minDim * (_minRingClearance + gap * 0.08);
  }

  double _outerRadius(double minDim, StealConfig config, double middleR) {
    final gap = config.middleToOuterGap.clamp(0.0, 1.0);
    return middleR + minDim * (_minRingClearance + gap * 0.08);
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
      _renderFlat(canvas, center, minDim, glowEnabled);
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
  ) {
    // Three lines: venue (top), title (middle), date (bottom)
    // Stacked below the logo center
    final baseY = center.dy + minDim * _flatOffsetRatio;

    final lines = [
      (_outerCurrent, _outerWords, _outerOpacity), // venue
      (_middleCurrent, _middleWords, _middleOpacity), // title
      (_innerCurrent, _innerWords, _innerOpacity), // date
    ];

    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].$1;
      final words = lines[i].$2;
      final lineOpacity = lines[i].$3;

      if (text.isEmpty || lineOpacity <= 0.01) continue;

      final y = baseY + (i - 1) * _flatLineHeight; // centered on middle line
      final effectiveOpacity = _opacity * lineOpacity;

      _drawFlatLine(canvas, text, words, Offset(center.dx, y), effectiveOpacity,
          glowEnabled);
    }
  }

  void _drawFlatLine(
    Canvas canvas,
    String text,
    List<_NeonWord> words,
    Offset center,
    double effectiveOpacity,
    bool glowEnabled,
  ) {
    if (text.isEmpty) return;

    final hsl = HSLColor.fromColor(_currentColor);
    final coreColor = hsl.withSaturation(0.15).withLightness(0.97).toColor();
    final innerHaloColor =
        hsl.withSaturation(1.0).withLightness(0.65).toColor();
    final outerBloomColor =
        hsl.withSaturation(1.0).withLightness(0.55).toColor();
    final deepBloomColor =
        hsl.withSaturation(0.9).withLightness(0.45).toColor();

    final wordList = words.isNotEmpty
        ? words
        : text
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map(_NeonWord.new)
            .toList();

    // Measure total width to center the line
    double totalWidth = 0.0;
    for (int wi = 0; wi < wordList.length; wi++) {
      for (final char in wordList[wi].text.characters) {
        final p = _measureChar(char);
        totalWidth += p;
      }
      if (wi < wordList.length - 1) {
        totalWidth += _fontSize * 0.6; // word gap
      }
    }

    double x = center.dx - totalWidth / 2;

    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;
      final chars = word.text.characters.toList();

      for (final char in chars) {
        final charWidth = _measureChar(char);

        canvas.save();
        canvas.translate(x + charWidth / 2, center.dy);

        final opacity = effectiveOpacity * wordBrightness;

        if (glowEnabled) {
          _paintChar(canvas, char,
              color: deepBloomColor.withValues(alpha: opacity * 0.12),
              blurRadius: 9.0);
          _paintChar(canvas, char,
              color: outerBloomColor.withValues(alpha: opacity * 0.30),
              blurRadius: 4.0);
          _paintChar(canvas, char,
              color: innerHaloColor.withValues(alpha: opacity * 0.75),
              blurRadius: 1.5);
          _paintChar(canvas, char,
              color: coreColor.withValues(alpha: opacity * 0.95),
              blurRadius: 0.0);
        } else {
          _paintChar(canvas, char,
              color: _currentColor.withValues(alpha: opacity * 0.9),
              blurRadius: 0.0,
              withDropShadow: true,
              dropShadowOpacity: opacity);
        }

        canvas.restore();
        x += charWidth;
      }

      if (wi < wordList.length - 1) {
        x += _fontSize * 0.6;
      }
    }
  }

  double _measureChar(String char) {
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: const TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.width;
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
          _opacity * _outerOpacity, glowEnabled);
    }
    if (_middleCurrent.isNotEmpty && _middleOpacity > 0.01) {
      _drawRing(canvas, _middleCurrent, _middleWords, center, middleR,
          _middleAngle, _opacity * _middleOpacity, glowEnabled);
    }
    if (_innerCurrent.isNotEmpty && _innerOpacity > 0.01) {
      _drawRing(canvas, _innerCurrent, _innerWords, center, innerR, _innerAngle,
          _opacity * _innerOpacity, glowEnabled);
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
  ) {
    if (text.isEmpty) return;

    final charAngle = (_fontSize * _letterSpacingBoost) / radius;
    final wordSpaceAngle = charAngle * _wordSpacingExtra;

    final hsl = HSLColor.fromColor(_currentColor);
    final coreColor = hsl.withSaturation(0.15).withLightness(0.97).toColor();
    final innerHaloColor =
        hsl.withSaturation(1.0).withLightness(0.65).toColor();
    final outerBloomColor =
        hsl.withSaturation(1.0).withLightness(0.55).toColor();
    final deepBloomColor =
        hsl.withSaturation(0.9).withLightness(0.45).toColor();

    double angle = startAngle - pi / 2;

    double totalSpan = 0.0;
    final wordList = words.isNotEmpty
        ? words
        : text
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map(_NeonWord.new)
            .toList();

    for (int wi = 0; wi < wordList.length; wi++) {
      totalSpan += charAngle * wordList[wi].text.characters.length;
      if (wi < wordList.length - 1) totalSpan += wordSpaceAngle;
    }
    angle = startAngle - pi / 2 - totalSpan / 2;

    for (int wi = 0; wi < wordList.length; wi++) {
      final word = wordList[wi];
      final wordBrightness = glowEnabled ? word.brightness : 1.0;
      final chars = word.text.characters.toList();

      for (int ci = 0; ci < chars.length; ci++) {
        final charX = center.dx + radius * cos(angle);
        final charY = center.dy + radius * sin(angle);

        canvas.save();
        canvas.translate(charX, charY);
        canvas.rotate(angle + pi / 2);

        final opacity = effectiveOpacity * wordBrightness;

        if (glowEnabled) {
          _paintChar(canvas, chars[ci],
              color: deepBloomColor.withValues(alpha: opacity * 0.12),
              blurRadius: 9.0);
          _paintChar(canvas, chars[ci],
              color: outerBloomColor.withValues(alpha: opacity * 0.30),
              blurRadius: 4.0);
          _paintChar(canvas, chars[ci],
              color: innerHaloColor.withValues(alpha: opacity * 0.75),
              blurRadius: 1.5);
          _paintChar(canvas, chars[ci],
              color: coreColor.withValues(alpha: opacity * 0.95),
              blurRadius: 0.0);
        } else {
          _paintChar(canvas, chars[ci],
              color: _currentColor.withValues(alpha: opacity * 0.9),
              blurRadius: 0.0,
              withDropShadow: true,
              dropShadowOpacity: opacity);
        }

        canvas.restore();
        angle += charAngle;
      }

      if (wi < wordList.length - 1) angle += wordSpaceAngle;
    }
  }

  void _paintChar(
    Canvas canvas,
    String char, {
    required Color color,
    required double blurRadius,
    bool withDropShadow = false,
    double dropShadowOpacity = 1.0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          shadows: withDropShadow
              ? [
                  Shadow(
                    color:
                        Colors.black.withValues(alpha: dropShadowOpacity * 0.7),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final offset = Offset(-painter.width / 2, -painter.height / 2);

    if (blurRadius > 0.0) {
      canvas.saveLayer(
        null,
        Paint()
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurRadius),
      );
      painter.paint(canvas, offset);
      canvas.restore();
    } else {
      painter.paint(canvas, offset);
    }
  }
}
