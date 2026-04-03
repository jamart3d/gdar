import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:gdar_design/typography/font_config.dart';

part 'steal_banner_render_flat.dart';
part 'steal_banner_render_ring.dart';

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

// -- Neon flicker per-word state --------------------------------------------

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

// -- Main component ---------------------------------------------------------

class StealBanner extends Component with HasGameReference<StealGame> {
  // -- Rotation ---------------------------------------------------------------
  static const double _baseRotationSpeed = 0.0006;

  // -- Base inner radius ------------------------------------------------------
  static const double _baseInnerRadiusRatio = 0.110;

  // -- Minimum ring clearance at gap=0 ---------------------------------------
  static const double _minRingClearance = 0.018;

  // -- Ring mode: default base spacing ---------------------------------------
  static const double _defaultFontSize = 11.0;

  // -- Flat mode layout -------------------------------------------------------
  // Line height in pixels. Gap is computed dynamically in _renderFlat.
  static const double _flatLineHeight = 16.0;

  // -- Fade -------------------------------------------------------------------
  static const double _fadeSpeed = 0.6;
  static const double _ringFadeSpeed = 1.2;

  // -- Char width cache (static — shared across instances) -------------------
  static final Map<String, double> _charWidthCache = {};

  // -- Rasterized glyph cache -------------------------------------------------
  static final Map<String, _RasterGlyph> _glyphCache = {};
  static double _lastGlowBlur = -1.0;
  static bool _lastGlowEnabled = false;
  static String? _lastFontFamily;
  static double _lastResolution = -1.0;

  // -- Per-ring state ---------------------------------------------------------
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

  // -- Shared -----------------------------------------------------------------
  Color _color = Colors.white;
  Color _currentColor = Colors.white;
  bool _visible = false;
  double _opacity = 0.0;

  final _rng = Random();

  // -- Public API -------------------------------------------------------------

  void updateBanner(
    String trackTitle,
    Color color, {
    bool showBanner = true,
    String venue = '',
    String date = '',
  }) {
    _color = color;
    _visible =
        showBanner &&
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

  // -- Flame update -----------------------------------------------------------

  @override
  void update(double dt) {
    // Clamp dt to prevent jumps during frame drops, matching StealGame behavior.
    final clampedDt = dt.clamp(0.0, 1.0 / 30.0);

    _currentColor = Color.lerp(_currentColor, _color, 0.025)!;

    final StealConfig config = game.config;
    final minDim = min(game.size.x, game.size.y);
    // Keep track-info motion independent from audio reactivity.
    const beatPulse = 0.0;
    const pulseScale = 1.0;
    final innerR = _innerRadius(minDim, config, beatPulse, pulseScale);
    final middleR = _middleRadius(minDim, config, innerR, pulseScale);
    final outerR = _outerRadius(minDim, config, middleR, pulseScale);

    if (_visible) {
      _innerAngle += _baseRotationSpeed * innerR * clampedDt;
      _middleAngle += _baseRotationSpeed * middleR * clampedDt;
      _outerAngle += _baseRotationSpeed * outerR * clampedDt;
      if (_innerAngle > 2 * pi) _innerAngle -= 2 * pi;
      if (_middleAngle > 2 * pi) _middleAngle -= 2 * pi;
      if (_outerAngle > 2 * pi) _outerAngle -= 2 * pi;
      _opacity = (_opacity + _fadeSpeed * clampedDt).clamp(0.0, 1.0);
    } else {
      _opacity = (_opacity - _fadeSpeed * clampedDt).clamp(0.0, 1.0);
    }

    _tickFade(
      clampedDt,
      _outerFadingOut,
      _outerOpacity,
      _outerPending,
      (v) {
        _outerOpacity = v;
      },
      (v) {
        _outerCurrent = v;
      },
      (v) {
        _outerPending = v;
      },
      (v) {
        _outerFadingOut = v;
      },
      (v) {
        _outerWords = v;
      },
    );
    _tickFade(
      clampedDt,
      _middleFadingOut,
      _middleOpacity,
      _middlePending,
      (v) {
        _middleOpacity = v;
      },
      (v) {
        _middleCurrent = v;
      },
      (v) {
        _middlePending = v;
      },
      (v) {
        _middleFadingOut = v;
      },
      (v) {
        _middleWords = v;
      },
    );
    _tickFade(
      clampedDt,
      _innerFadingOut,
      _innerOpacity,
      _innerPending,
      (v) {
        _innerOpacity = v;
      },
      (v) {
        _innerCurrent = v;
      },
      (v) {
        _innerPending = v;
      },
      (v) {
        _innerFadingOut = v;
      },
      (v) {
        _innerWords = v;
      },
    );

    if (config.bannerGlow && config.bannerFlicker > 0.0) {
      final strength = config.bannerFlicker.clamp(0.0, 1.0);
      for (final words in [_outerWords, _middleWords, _innerWords]) {
        for (final word in words) {
          _tickWordFlicker(word, clampedDt, strength);
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

  // -- Per-word neon flicker phase machine ------------------------------------

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
        final buzzProgress = (1.0 - (word.eventTimer / (word.buzzAmp * 4.0)))
            .clamp(0.0, 1.0);
        final envelope = sin(buzzProgress * pi).clamp(0.0, 1.0);
        word.brightness = (1.0 + osc * word.buzzAmp * envelope).clamp(
          0.82,
          1.0,
        );
        if (word.eventTimer <= 0.0) {
          // Ease back rather than snap
          word.brightness = (word.brightness + (1.0 - word.brightness) * 0.4)
              .clamp(0.9, 1.0);
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

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    final w = game.size.x;
    final h = game.size.y;
    if (w < 2 || h < 2) return;

    final config = game.config;
    final logoPos = game.smoothedLogoPos;
    final minDim = min(w, h);
    final glowEnabled = config.bannerGlow;
    final isFlat = config.bannerDisplayMode == 'flat';
    final center = Offset(logoPos.dx * w, logoPos.dy * h);

    const beatPulse = 0.0;
    const pulseScale = 1.0;

    if (isFlat) {
      _renderFlat(
        canvas,
        center,
        minDim,
        glowEnabled,
        config,
        beatPulse: beatPulse,
        pulseScale: pulseScale,
      );
    } else {
      _renderRings(
        canvas,
        center,
        minDim,
        glowEnabled,
        config,
        beatPulse: beatPulse,
        pulseScale: pulseScale,
      );
    }
  }
}

// end of file
