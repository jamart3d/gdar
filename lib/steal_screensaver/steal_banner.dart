import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';

/// Renders three circular rotating text rings that orbit the Steal Your Face logo.
///
/// Outer ring:  venue        — clockwise, fastest (largest radius)
/// Middle ring: track title  — clockwise, medium
/// Inner ring:  date         — clockwise, slowest (smallest radius)
///
/// When bannerGlow is enabled, each word gets independent neon-style flicker
/// driven by a phase machine: idle → buzz → dropout → recover → idle.
/// The bannerFlicker value (0–1) scales event frequency and amplitude.
/// Plain text mode is unaffected.

// ── Neon flicker per-word state ────────────────────────────────────────────

enum _FlickerPhase { idle, buzz, dropout, recover }

class _NeonWord {
  final String text;
  double brightness = 1.0; // applied as opacity multiplier per-word
  double target = 1.0;
  double eventTimer = 0.0; // time until next phase transition
  _FlickerPhase phase = _FlickerPhase.idle;
  double buzzFreq = 0.0; // oscillation rate during buzz phase
  double buzzAmp = 0.0; // amplitude of buzz oscillation

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
  // Extra angle between words (in addition to normal letter spacing)
  static const double _wordSpacingExtra = 1.6;

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
      newText: date,
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
    if (newText == current) {
      return;
    }
    if (opacity <= 0.05 || current.isEmpty) {
      setCurrent(newText);
      setFadingOut(false);
      setWords(_buildWords(newText));
    } else {
      setPending(newText);
      setFadingOut(true);
    }
  }

  /// Split text into words and create _NeonWord objects with randomised
  /// initial timers so they never all fire at the same time.
  List<_NeonWord> _buildWords(String text) {
    if (text.isEmpty) {
      return [];
    }
    final parts = text.split(' ').where((w) => w.isNotEmpty).toList();
    return parts.map((w) {
      final word = _NeonWord(w);
      // Stagger initial idle timers 0–3s so words desync immediately
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
      if (_innerAngle > 2 * pi) {
        _innerAngle -= 2 * pi;
      }
      if (_middleAngle > 2 * pi) {
        _middleAngle -= 2 * pi;
      }
      if (_outerAngle > 2 * pi) {
        _outerAngle -= 2 * pi;
      }
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

    // Tick per-word flicker only when glow is on
    if (config.bannerGlow && config.bannerFlicker > 0.0) {
      final strength = config.bannerFlicker.clamp(0.0, 1.0);
      for (final words in [_outerWords, _middleWords, _innerWords]) {
        for (final word in words) {
          _tickWordFlicker(word, dt, strength);
        }
      }
    } else {
      // Reset all word brightnesses when flicker is off
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
        // Subtle jitter — brightness near 1.0 with tiny noise
        final jitter = (strength * 0.03) * (_rng.nextDouble() * 2 - 1);
        word.brightness =
            (word.brightness + (1.0 + jitter - word.brightness) * 8.0 * dt)
                .clamp(0.85, 1.0);

        if (word.eventTimer <= 0.0) {
          // Decide: buzz or dropout, weighted by strength
          final doBuzz = _rng.nextDouble() < 0.65;
          if (doBuzz) {
            word.phase = _FlickerPhase.buzz;
            // Duration: 60–200ms, more frequent at high strength
            word.eventTimer =
                ui.lerpDouble(0.20, 0.06, strength)! + _rng.nextDouble() * 0.14;
            word.buzzFreq = 15.0 + _rng.nextDouble() * 10.0; // 15–25 Hz
            word.buzzAmp = ui.lerpDouble(0.04, 0.18, strength)!;
          } else {
            word.phase = _FlickerPhase.dropout;
            word.eventTimer = 0.025 + _rng.nextDouble() * 0.035; // 25–60ms drop
            word.target = ui.lerpDouble(0.55, 0.08, strength)!; // how dark
          }
          // Next idle: longer at low strength (rare events), shorter at high
          // (but this sets the NEXT idle after recovery, updated in recover)
        }

      case _FlickerPhase.buzz:
        // Fast oscillation around 1.0
        final osc = sin(word.buzzFreq * 2 * pi * (1.0 - word.eventTimer));
        word.brightness = (1.0 + osc * word.buzzAmp).clamp(0.7, 1.0);
        if (word.eventTimer <= 0.0) {
          word.brightness = 1.0;
          word.phase = _FlickerPhase.idle;
          word.eventTimer = _nextIdleTime(strength);
        }

      case _FlickerPhase.dropout:
        // Lerp quickly toward dark target
        word.brightness += (word.target - word.brightness) * 20.0 * dt;
        if (word.eventTimer <= 0.0) {
          word.phase = _FlickerPhase.recover;
          word.eventTimer =
              0.04 + _rng.nextDouble() * 0.08; // hold dark 40–120ms
        }

      case _FlickerPhase.recover:
        // Snap back toward full brightness
        word.brightness += (1.0 - word.brightness) * 12.0 * dt;
        if (word.eventTimer <= 0.0) {
          word.brightness = 1.0;
          word.phase = _FlickerPhase.idle;
          word.eventTimer = _nextIdleTime(strength);
        }
    }
  }

  double _nextIdleTime(double strength) {
    // Low strength: long quiet periods (2–6s). High strength: short (0.3–1.2s).
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
    if (_opacity <= 0.01) {
      return;
    }

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) {
      return;
    }

    final StealConfig config = game.config;
    final drift = config.orbitDrift.clamp(0.0, 2.0);
    final t = game.time * config.flowSpeed.clamp(0.0, 2.0) * 0.5;

    final px = 0.5 + 0.25 * drift * sin(t * 1.3) + 0.1 * drift * sin(t * 2.9);
    final py = 0.5 + 0.25 * drift * cos(t * 1.7) + 0.1 * drift * cos(t * 3.1);
    final center = Offset(px * w, py * h);

    final minDim = min(w, h);
    final innerR = _innerRadius(minDim, config);
    final middleR = _middleRadius(minDim, config, innerR);
    final outerR = _outerRadius(minDim, config, middleR);

    final glowEnabled = config.bannerGlow;

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
    if (text.isEmpty) {
      return;
    }

    final charAngle = (_fontSize * _letterSpacingBoost) / radius;
    final wordSpaceAngle = charAngle * _wordSpacingExtra;

    final hsl = HSLColor.fromColor(_currentColor);

    // Tight glow layers (only computed if glow enabled)
    // Core: near-white, no blur — the lit tube
    final coreColor = hsl.withSaturation(0.15).withLightness(0.97).toColor();
    // Inner halo: saturated, very tight blur — color fringe against letters
    final innerHaloColor =
        hsl.withSaturation(1.0).withLightness(0.65).toColor();
    // Outer bloom: same hue, soft spread
    final outerBloomColor =
        hsl.withSaturation(1.0).withLightness(0.55).toColor();
    // Deep bloom: faint wide cast
    final deepBloomColor =
        hsl.withSaturation(0.9).withLightness(0.45).toColor();

    // Build list of (wordIndex, charIndex, char) with angles
    // so we can look up per-word brightness at render time
    double angle = startAngle - pi / 2;

    // First pass: compute total arc span to center it
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
      if (wi < wordList.length - 1) {
        totalSpan += wordSpaceAngle;
      }
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
          // Layer 1 — deep bloom: wide, faint
          _paintChar(canvas, chars[ci],
              color: deepBloomColor.withValues(alpha: opacity * 0.12),
              blurRadius: 9.0);
          // Layer 2 — outer bloom: medium spread
          _paintChar(canvas, chars[ci],
              color: outerBloomColor.withValues(alpha: opacity * 0.30),
              blurRadius: 4.0);
          // Layer 3 — inner halo: tight fringe right against letters
          _paintChar(canvas, chars[ci],
              color: innerHaloColor.withValues(alpha: opacity * 0.75),
              blurRadius: 1.5);
          // Layer 4 — core: crisp white tube
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

      // Word gap
      if (wi < wordList.length - 1) {
        angle += wordSpaceAngle;
      }
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
