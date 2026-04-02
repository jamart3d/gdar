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

  /// Display mode: 'corner', 'circular', 'ekg', 'circular_ekg', 'beat_debug', or 'off'.
  String graphMode = 'off';

  /// Diagnostic fields for beat_debug overlay.
  int? debugSessionId;
  bool debugReactorConnected = false;

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
  static const double _beatFlashDecayPerSec =
      3.5; // ~285ms visible — more forgiving for live recordings
  static const double _beatBarFallSmoothing =
      7.0; // faster than bands but not jarring

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
  double _ekgAccum = 0.0; // time accumulator for frame-rate-independent scroll
  double _ekgRotation = 0.0; // slow angular rotation for circular_ekg
  static const double _ekgSampleRate = 60.0; // samples/sec regardless of fps
  HSLColor _ekgHsl = const HSLColor.fromAHSL(
    1.0,
    195.0,
    1.0,
    0.6,
  ); // smoothed toward palette

  // Short-lived beat flash factor for HUD accent.
  double _beatFlash = 0.0;

  // Per-algorithm flash values for beat_debug mode (6 algorithms).
  final List<double> _algoFlash = List.filled(6, 0.0);
  // Smoothed per-algorithm diagnostic score display (0–3).
  final List<double> _algoLevel = List.filled(6, 0.0);
  static const List<String> _algoLabels = [
    'BASS\n0-250',
    'MID\n250-4k',
    'BROAD\nB+M',
    'ALL\nBANDS',
    'EMA\nMID',
    'TREB\n4k+',
  ];

  // ── VU meter state ───────────────────────────────────────────────────────
  static const double _vuRiseSmoothing = 12.0;
  static const double _vuFallSmoothing = 2.2;
  static const double _vuPeakDecayPerSec = 0.5;
  static const double _vuWidth = 155.0;
  static const double _vuHeight = 110.0;
  static const double _vuNeedleLength = 74.0;
  static const double _vuSweepHalf = 1.1; // radians half-swing (~63°)

  double _vuLeft = 0.0;
  double _vuRight = 0.0;
  double _vuPeakLeft = 0.0;
  double _vuPeakRight = 0.0;
  double _vuRawLeft = 0.0;
  double _vuRawRight = 0.0;
  double _vuDrive = 1.0;

  // ── Oscilloscope state ───────────────────────────────────────────────────
  List<double> _scopeWaveform = const [];
  List<double> _scopeWaveformL = const [];
  List<double> _scopeWaveformR = const [];
  // Rolling peak for auto-gain — decays slowly so gain doesn't jump on silence.
  double _scopePeak = 0.05;
  double _scopePeakL = 0.05;
  double _scopePeakR = 0.05;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  String _padRightField(String value, int width) {
    if (value.length >= width) return value;
    return value.padRight(width);
  }

  String _padLeftField(String value, int width) {
    if (value.length >= width) return value;
    return value.padLeft(width);
  }

  void _paintDebugText(
    Canvas canvas,
    String text,
    TextStyle style,
    double x,
    double y, {
    double? maxWidth,
    int? maxLines,
    String? ellipsis,
  }) {
    _textPainter.text = TextSpan(text: text, style: style);
    _textPainter.maxLines = maxLines;
    _textPainter.ellipsis = ellipsis;
    _textPainter.layout(maxWidth: maxWidth ?? double.infinity);
    _textPainter.paint(canvas, Offset(x, y));
    _textPainter.maxLines = null;
    _textPainter.ellipsis = null;
  }

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

    if (graphMode == 'corner' || graphMode == 'corner_only') {
      _updateCornerHeights(dt);
      _updatePeakHolds(_cornerHeights, _cornerPeakHeights, _maxBarHeight, dt);
    }
    if (graphMode == 'corner_only') {
      _updateVuLevels(dt);
    }
    if (graphMode == 'circular') {
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
    if (graphMode == 'circular_ekg') {
      _ekgRotation += dt * 0.15;
      if (_ekgRotation > 2 * pi) _ekgRotation -= 2 * pi;
    }

    if (graphMode == 'vu') _updateVuLevels(dt);

    if (graphMode == 'beat_debug') {
      final algos = energy.beatAlgos;
      final levels = energy.algoLevels;
      for (int i = 0; i < _algoFlash.length; i++) {
        // Flash on beat fire.
        final fired = i < algos.length && algos[i];
        if (fired) {
          _algoFlash[i] = 1.0;
        } else {
          _algoFlash[i] = (_algoFlash[i] - _beatFlashDecayPerSec * dt).clamp(
            0.0,
            1.0,
          );
        }
        // Smooth the continuous level toward the incoming ratio.
        final target = i < levels.length ? levels[i] : 0.0;
        _algoLevel[i] += (target - _algoLevel[i]) * 12.0 * dt;
      }
    }

    final wantsScope = graphMode == 'scope' || graphMode == 'corner_only';
    if (wantsScope && energy.waveform.isNotEmpty) {
      _scopeWaveform = energy.waveform;
      for (final v in _scopeWaveform) {
        if (v.abs() > _scopePeak) _scopePeak = v.abs();
      }
    }
    if (wantsScope &&
        energy.waveformL.isNotEmpty &&
        energy.waveformR.isNotEmpty) {
      _scopeWaveformL = energy.waveformL;
      _scopeWaveformR = energy.waveformR;
      for (final v in _scopeWaveformL) {
        if (v.abs() > _scopePeakL) _scopePeakL = v.abs();
      }
      for (final v in _scopeWaveformR) {
        if (v.abs() > _scopePeakR) _scopePeakR = v.abs();
      }
    } else if (wantsScope) {
      _scopeWaveformL = const [];
      _scopeWaveformR = const [];
    }
    if (wantsScope) {
      _scopePeak = max(_scopePeak * 0.995, 0.001);
      _scopePeakL = max(_scopePeakL * 0.995, 0.001);
      _scopePeakR = max(_scopePeakR * 0.995, 0.001);
    }

    // Smoothly lerp EKG color toward the current palette — same pace as
    // StealBackground's _colorLerpSpeed so it tracks the visual transition.
    _updateEkgColor(dt);
  }

  void _updateEkgColor(double dt) {
    final paletteColors =
        StealConfig.palettes[game.config.palette] ??
        StealConfig.palettes.values.first;
    final rawColor = paletteColors.isNotEmpty
        ? paletteColors.first
        : Colors.white;
    final baseColor = rawColor.computeLuminance() > 0.85
        ? Colors.white
        : rawColor;
    final target = HSLColor.fromColor(baseColor);
    // dt * 1.5 ≈ 0.025 per frame at 60fps — matches background shader lerp speed.
    _ekgHsl = HSLColor.lerp(_ekgHsl, target, (dt * 1.5).clamp(0.0, 1.0))!;
  }

  /// Drives the EKG history at a fixed sample rate so scroll speed is consistent
  /// regardless of device frame rate (60fps vs 30fps on Google TV).
  void _updateEkgHistory(double dt) {
    _ekgAccum += dt;
    const interval = 1.0 / _ekgSampleRate;
    while (_ekgAccum >= interval) {
      _ekgAccum -= interval;
      _pushEkgSample(interval);
    }
  }

  /// Extracts guitar-range energy (bands 2-4, 250-2000 Hz) and pushes one
  /// sample into the rolling history buffer.
  void _pushEkgSample(double dt) {
    final bands = energy.bands;
    if (bands.length < 5) return;

    final target = (bands[2] + bands[3] + bands[4]) / 3.0;

    if (target > _lastEkgVal) {
      _lastEkgVal += (target - _lastEkgVal) * _ekgRiseSmoothing * dt;
    } else {
      _lastEkgVal += (target - _lastEkgVal) * _ekgFallSmoothing * dt;
    }

    for (int i = 0; i < _ekgSampleCount - 1; i++) {
      _ekgHistory[i] = _ekgHistory[i + 1];
    }
    _ekgHistory[_ekgSampleCount - 1] = _lastEkgVal.clamp(0.0, 1.0);
  }

  // True when latest AudioEnergy carries real stereo PCM from AudioPlaybackCapture.
  bool _hasRealStereo = false;

  void _updateVuLevels(double dt) {
    double targetL;
    double targetR;

    if (energy.waveformL.isNotEmpty && energy.waveformR.isNotEmpty) {
      // Real stereo from AudioPlaybackCapture — compute RMS of each channel.
      // 2.5× boost maps typical speech/music RMS (~0.1–0.3) into needle range.
      _hasRealStereo = true;
      _vuDrive = 2.5;
      _vuRawLeft = _rms(energy.waveformL).clamp(0.0, 1.0);
      _vuRawRight = _rms(energy.waveformR).clamp(0.0, 1.0);
      targetL = (_vuRawLeft * _vuDrive).clamp(0.0, 1.0);
      targetR = (_vuRawRight * _vuDrive).clamp(0.0, 1.0);
    } else {
      // Fallback: fake stereo by splitting 8-band FFT (lo bands → L, hi → R).
      _hasRealStereo = false;
      _vuDrive = 1.0;
      final bands = energy.bands;
      _vuRawLeft =
          (bands.length >= 8
                  ? (bands[0] + bands[1] + bands[2] + bands[3]) / 4.0
                  : energy.bass)
              .clamp(0.0, 1.0);
      _vuRawRight =
          (bands.length >= 8
                  ? (bands[4] + bands[5] + bands[6] + bands[7]) / 4.0
                  : energy.treble)
              .clamp(0.0, 1.0);
      targetL = (_vuRawLeft * _vuDrive).clamp(0.0, 1.0);
      targetR = (_vuRawRight * _vuDrive).clamp(0.0, 1.0);
    }

    _vuLeft = _vuSmooth(_vuLeft, targetL, dt);
    _vuRight = _vuSmooth(_vuRight, targetR, dt);

    if (_vuLeft >= _vuPeakLeft) {
      _vuPeakLeft = _vuLeft;
    } else {
      _vuPeakLeft = max(0.0, _vuPeakLeft - _vuPeakDecayPerSec * dt);
    }
    if (_vuRight >= _vuPeakRight) {
      _vuPeakRight = _vuRight;
    } else {
      _vuPeakRight = max(0.0, _vuPeakRight - _vuPeakDecayPerSec * dt);
    }
  }

  double _vuSmooth(double current, double target, double dt) {
    if (target > current) {
      return current + (target - current) * _vuRiseSmoothing * dt;
    } else {
      return current + (target - current) * _vuFallSmoothing * dt;
    }
  }

  double _rms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    var sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
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

    // Beat bar (index 8): instant attack, faster decay than regular bands.
    final targetBeat = energy.isBeat ? _maxBarHeight : 0.0;
    final currentBeat = _cornerHeights[_bandCount];
    if (targetBeat > currentBeat) {
      _cornerHeights[_bandCount] = targetBeat;
    } else {
      _cornerHeights[_bandCount] +=
          (targetBeat - currentBeat) * _beatBarFallSmoothing * dt;
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
      case 'corner_only':
        _renderCorner(canvas);
        _renderVu(canvas);
        // Scope mirrors bar graph: same panel size, right-anchored.
        _renderScope(canvas, panelWidth: 220.0);
      case 'circular':
        _renderCircular(canvas);
      case 'ekg':
        _renderEKG(canvas);
      case 'circular_ekg':
        _renderCircularEKG(canvas);
      case 'vu':
        _renderVu(canvas);
      case 'scope':
        _renderScope(canvas);
      case 'beat_debug':
        _renderBeatDebug(canvas);
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

    // Use the smoothed palette color — no per-frame snap on palette cycle.
    final hsl = _ekgHsl;

    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      // t=0 → front line (vivid, full lightness), t=1 → back line (dark, dim).
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

      // Smooth bezier path through midpoints — organic waveform shape.
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

    // Label uses the smoothed front-line color.
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

    // Use the smoothed palette color — no per-frame snap on palette cycle.
    final hsl = _ekgHsl;

    final replication = game.config.ekgReplication.clamp(1, 10);
    final spread = game.config.ekgSpread;

    for (int r = replication - 1; r >= 0; r--) {
      // t=0 → front ring (vivid, full lightness), t=1 → back ring (dark, dim).
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

      // Build point ring with slow rotation offset applied to every angle.
      final points = <Offset>[];
      for (int i = 0; i < _ekgSampleCount; i++) {
        final angle = (i / _ekgSampleCount) * 2 * pi - (pi / 2) + _ekgRotation;
        final rad =
            baseRadius + radiusOffset + (_ekgHistory[i] * _ekgMaxHeight * 0.8);
        points.add(Offset(cx + rad * cos(angle), cy + rad * sin(angle)));
      }

      // Seamless closed bezier: start at midpoint between last and first
      // so the join is smoothed by the curve, not a hard corner.
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
      // Path ends at startMid — no gap, no seam.

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

  /// Render 8-bar EQ + Beat anchored bottom-left using FFT band data.
  void _renderCorner(Canvas canvas) {
    final drift = _burnInDrift();
    final startY = game.size.y - _bottomPadding + drift.dy;
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
        // Beat bar gets 2× sigma and a much stronger alpha on flash.
        final glowAlpha = isBeatBar
            ? (0.35 + _beatFlash * 0.55).clamp(0.0, 1.0)
            : (0.22 + _beatFlash * 0.18).clamp(0.0, 1.0);
        final glowSigma = isBeatBar ? _glowSigma * 2.0 : _glowSigma;
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowAlpha)
          ..style = PaintingStyle.fill
          ..maskFilter = isWasmSafeMode()
              ? null
              : MaskFilter.blur(BlurStyle.normal, glowSigma);
        canvas.drawRRect(rect, glowPaint);
      }

      // Beat bar top alpha brightens with flash; other bars use fixed alpha.
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

      // White spark at beat bar top on strong flash.
      if (isBeatBar && _beatFlash > 0.45) {
        final sparkAlpha = ((_beatFlash - 0.45) / 0.55).clamp(0.0, 1.0);
        final sparkPaint = Paint()
          ..color = Colors.white.withValues(alpha: sparkAlpha * 0.95)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(barLeft - 1.0, barTop),
          Offset(barLeft + _barWidth + 1.0, barTop),
          sparkPaint,
        );
      }

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
          color: isBeatBar
              ? Colors.white.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: isBeatBar ? FontWeight.w700 : FontWeight.w600,
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

  /// Render phosphor oscilloscope — raw PCM waveform, bottom strip.
  /// When PCM is flat (common on some Android TV chipsets), falls back to a
  /// smooth synthesized waveform derived from the 8 FFT bands so the scope
  /// always shows something audio-reactive.
  ///
  /// [panelWidth]: when provided the scope is right-anchored with a fixed
  /// panel width, mirroring the bar-graph panel on the left.  The waveform
  /// height matches [_maxBarHeight] so both panels share the same vertical
  /// footprint.  When omitted the scope fills the full screen width (standalone
  /// 'scope' mode).
  void _renderScope(Canvas canvas, {double? panelWidth}) {
    final drift = _burnInDrift();
    final w = game.size.x;
    final h = game.size.y;

    // Panel mode (corner_only): same height as bar graph, right-anchored.
    // Standalone mode: fill width, slightly shorter trace.
    final isPanelMode = panelWidth != null;
    final scopeHeight = isPanelMode ? _maxBarHeight : 70.0;
    final availableWidth = isPanelMode ? panelWidth : w - _leftPadding * 2;
    final startX =
        (isPanelMode ? w - _leftPadding - panelWidth : _leftPadding) + drift.dx;
    // Center of waveform sits at the vertical midpoint of the bar-graph area.
    final centerY =
        h - _bottomPadding + drift.dy - (isPanelMode ? scopeHeight / 2 : 0.0);

    // P31 phosphor green
    const phosphorColor = Color(0xFF33FF66);

    // Soft-clip: atan(v*50)/(π/2) ≈ 50v for tiny v, approaches ±1 asymptotically.
    double softClip(double v) => atan(v * 50.0) / (pi / 2);

    // Panel background — only in corner_only mode, mirrors bar-graph HUD panel.
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
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = Colors.white.withValues(alpha: _isBalanced ? 0.035 : 0.06)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14 + _beatFlash * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Graticule: always visible — center line and ±50% bounds.
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

    // Beat shifts trace colour toward warm white for one flash cycle.
    final traceColor = _beatFlash > 0.01
        ? Color.lerp(phosphorColor, const Color(0xFFFFFFFF), _beatFlash * 0.5)!
        : phosphorColor;

    void drawTrace(Path path) {
      if (_glowSigma > 0.0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = traceColor.withValues(alpha: 0.22 + _beatFlash * 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = isWasmSafeMode()
                ? null
                : MaskFilter.blur(BlurStyle.normal, _glowSigma),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = traceColor.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + _beatFlash * 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    void drawStereoLane(
      List<double> waveform,
      double laneCenterY,
      double laneHeight,
      Color color,
    ) {
      if (waveform.length < 2) return;
      final path = Path();
      path.moveTo(
        startX,
        laneCenterY - softClip(waveform[0]) * (laneHeight / 2),
      );
      for (int i = 1; i < waveform.length; i++) {
        final x = startX + (i / (waveform.length - 1)) * availableWidth;
        final y = laneCenterY - softClip(waveform[i]) * (laneHeight / 2);
        path.lineTo(x, y);
      }
      if (_glowSigma > 0.0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.18 + _beatFlash * 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = isWasmSafeMode()
                ? null
                : MaskFilter.blur(BlurStyle.normal, _glowSigma),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + _beatFlash * 0.6
          ..strokeCap = StrokeCap.round,
      );
    }

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
          Paint()
            ..color = phosphorColor.withValues(alpha: 0.08)
            ..strokeWidth = 0.5,
        );
      }

      drawStereoLane(_scopeWaveformL, upperCenterY, laneHeight, leftColor);
      drawStereoLane(_scopeWaveformR, lowerCenterY, laneHeight, rightColor);

      _textPainter.text = TextSpan(
        text: 'OSC PCM ST  256pt',
        style: TextStyle(
          color: phosphorColor.withValues(alpha: 0.42),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(startX, centerY + scopeHeight / 2 + 6.0),
      );

      _textPainter.text = TextSpan(
        text:
            'L ${(_scopePeakL * 100).clamp(0.0, 100.0).toStringAsFixed(0).padLeft(3)}%  '
            'R ${(_scopePeakR * 100).clamp(0.0, 100.0).toStringAsFixed(0).padLeft(3)}%',
        style: TextStyle(
          color: phosphorColor.withValues(alpha: 0.32),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      canvas.save();
      canvas.translate(
        startX + availableWidth - _textPainter.width,
        centerY + scopeHeight / 2 + 6.0,
      );
      _textPainter.paint(canvas, Offset.zero);
      canvas.restore();

      _textPainter.text = TextSpan(
        text: 'L',
        style: TextStyle(
          color: leftColor.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(startX + 4, upperCenterY - laneHeight / 2),
      );

      _textPainter.text = TextSpan(
        text: 'R',
        style: TextStyle(
          color: rightColor.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(startX + 4, lowerCenterY - laneHeight / 2),
      );
      return;
    }

    if (hasPcm) {
      // ── Real PCM path ─────────────────────────────────────────────────────
      final path = Path();
      path.moveTo(startX, centerY - softClip(waveform[0]) * (scopeHeight / 2));
      for (int i = 1; i < waveform.length; i++) {
        final x = startX + (i / (waveform.length - 1)) * availableWidth;
        final y = centerY - softClip(waveform[i]) * (scopeHeight / 2);
        path.lineTo(x, y);
      }
      drawTrace(path);

      // Label bottom-left.
      canvas.save();
      canvas.translate(startX, centerY + scopeHeight / 2 + 6.0);
      _textPainter.text = TextSpan(
        text: 'OSC PCM  256pt',
        style: TextStyle(
          color: phosphorColor.withValues(alpha: 0.4),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset.zero);
      canvas.restore();

      // Peak level readout — right side.
      final peakPct = (_scopePeak * 100).clamp(0.0, 100.0).toStringAsFixed(0);
      _textPainter.text = TextSpan(
        text: 'LVL $peakPct%',
        style: TextStyle(
          color: phosphorColor.withValues(alpha: 0.3),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      canvas.save();
      canvas.translate(
        startX + availableWidth - _textPainter.width,
        centerY + scopeHeight / 2 + 6.0,
      );
      _textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      // ── FFT-band synthesized waveform fallback ────────────────────────────
      // PCM capture returns flat data on some Android TV chipsets.  Instead of
      // a dead flat line we build a smooth bezier from the 8 FFT bands:
      //   • 9 control points spaced evenly across the scope width.
      //   • Band amplitude alternates sign (±) to create an oscillating shape.
      //   • softClip keeps the curve within the display bounds.
      final bands = energy.bands;
      final hasSignal = bands.length >= 8 && energy.overall > 0.008;

      if (hasSignal) {
        // Time-varying additive synthesis: each band drives a sinusoid at a
        // characteristic visual frequency.  The scope window advances with
        // game.time so the trace scrolls continuously — left = oldest, right =
        // newest.  Band energy sets each component's amplitude, giving a live
        // waveform that reacts to bass, mids, and treble independently.
        //
        // Visual frequencies (Hz): chosen so the scope shows 0.5-4 full cycles
        // of each component in the 0.5-second window — visually readable.
        const freqs = [0.2, 0.4, 0.7, 1.1, 1.6, 2.25, 3.0, 4.0];
        const windowSecs = 4.0; // seconds of signal shown across scope width
        const numPoints = 128;

        final t = game.time;
        // Pre-scale each band; softClip keeps amplitude in ±1 territory.
        final amps = List<double>.generate(
          8,
          (b) => b < bands.length ? softClip(bands[b] * 3.0) : 0.0,
        );

        final path = Path();
        for (int i = 0; i < numPoints; i++) {
          final x = startX + (i / (numPoints - 1)) * availableWidth;
          // Map x to a time offset so the trace scrolls left as time advances.
          final tx = t - windowSecs + (i / (numPoints - 1)) * windowSecs;
          // Sum sinusoids — 8 components give a rich, complex waveform.
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
        drawTrace(path);

        // Label indicating fallback mode.
        canvas.save();
        canvas.translate(startX, centerY + scopeHeight / 2 + 6.0);
        _textPainter.text = TextSpan(
          text: 'OSC FFT-SYN  8B',
          style: TextStyle(
            color: phosphorColor.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            fontFamily: 'RobotoMono',
          ),
        );
        _textPainter.layout();
        _textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      } else {
        // Completely silent — pulsing flat line.
        final flatAlpha = 0.15 + energy.overall * 0.35 + _beatFlash * 0.3;
        canvas.drawLine(
          Offset(startX, centerY),
          Offset(startX + availableWidth, centerY),
          Paint()
            ..color = phosphorColor.withValues(alpha: flatAlpha.clamp(0.0, 1.0))
            ..strokeWidth = 1.2,
        );

        canvas.save();
        canvas.translate(startX, centerY + scopeHeight / 2 + 6.0);
        _textPainter.text = TextSpan(
          text: 'OSC — SILENT',
          style: TextStyle(
            color: phosphorColor.withValues(alpha: 0.25),
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
    }
  }

  /// Render dual VU needle meters.
  /// When AudioPlaybackCapture is active, uses real L/R RMS levels.
  /// Otherwise fakes stereo by splitting low vs high FFT bands.
  void _renderVu(Canvas canvas) {
    final drift = _burnInDrift();
    final cx = game.size.x / 2 + drift.dx;
    final baseY = game.size.y - _bottomPadding + drift.dy;
    const gap = 44.0;
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
    _drawLedStrip(canvas, cx, baseY, drift);
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
    // Panel background
    if (!_isFast) {
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bottom - _vuHeight, _vuWidth, _vuHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12 + _beatFlash * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    final pivotX = left + _vuWidth / 2;
    final pivotY = bottom - 14.0;
    const arcRadius = _vuNeedleLength + 5.0;

    // Colored arc zones (background)
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
      Paint()
        ..color = const Color(0xFF4AF3C6).withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    canvas.drawArc(
      arcRect,
      arcStart + totalSweep * 0.65,
      totalSweep * 0.17,
      false,
      Paint()
        ..color = const Color(0xFFFFE66D).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    canvas.drawArc(
      arcRect,
      arcStart + totalSweep * 0.82,
      totalSweep * 0.18,
      false,
      Paint()
        ..color = const Color(0xFFFF4444).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );

    // Scale tick marks
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
        Paint()
          ..color = tickColor.withValues(alpha: 0.65)
          ..strokeWidth = frac == 0.72 ? 1.5 : 0.8,
      );

      if (showLabel[m]) {
        _textPainter.text = TextSpan(
          text: markLabels[m],
          style: TextStyle(
            color: tickColor.withValues(alpha: 0.55),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            fontFamily: 'RobotoMono',
          ),
        );
        _textPainter.layout();
        final lx =
            pivotX + cos(angle) * (arcRadius + 15) - _textPainter.width / 2;
        final ly =
            pivotY + sin(angle) * (arcRadius + 15) - _textPainter.height / 2;
        _textPainter.paint(canvas, Offset(lx, ly));
      }
    }

    // Peak hold dot on arc
    if (peakLevel > 0.02) {
      final peakAngle =
          -pi / 2 + (-_vuSweepHalf + peakLevel.clamp(0.0, 1.0) * totalSweep);
      final peakColor = peakLevel < 0.65
          ? const Color(0xFF4AF3C6)
          : peakLevel < 0.82
          ? const Color(0xFFFFE66D)
          : const Color(0xFFFF5555);
      canvas.drawCircle(
        Offset(
          pivotX + cos(peakAngle) * (_vuNeedleLength - 3),
          pivotY + sin(peakAngle) * (_vuNeedleLength - 3),
        ),
        2.2,
        Paint()
          ..color = peakColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill,
      );
    }

    // Needle
    final needleLevel = level.clamp(0.0, 1.0);
    final needleAngle = -pi / 2 + (-_vuSweepHalf + needleLevel * totalSweep);
    final tipX = pivotX + cos(needleAngle) * _vuNeedleLength;
    final tipY = pivotY + sin(needleAngle) * _vuNeedleLength;

    final needleColor = needleLevel < 0.65
        ? const Color(0xFFDDDDDD)
        : needleLevel < 0.82
        ? const Color(0xFFFFE66D)
        : const Color(0xFFFF5555);

    if (_glowSigma > 0.0 && needleLevel > 0.05) {
      canvas.drawLine(
        Offset(pivotX, pivotY),
        Offset(tipX, tipY),
        Paint()
          ..color = needleColor.withValues(alpha: 0.18)
          ..strokeWidth = 3.0
          ..maskFilter = isWasmSafeMode()
              ? null
              : const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }
    canvas.drawLine(
      Offset(pivotX, pivotY),
      Offset(tipX, tipY),
      Paint()
        ..color = needleColor.withValues(alpha: 0.95)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Pivot
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

    // Channel and range labels
    _textPainter.text = TextSpan(
      text: chanLabel,
      style: const TextStyle(
        color: Color(0xFF99AABB),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(left + 7, bottom - _vuHeight + 6));

    _textPainter.text = TextSpan(
      text: rangeLabel,
      style: TextStyle(
        color: const Color(0xFF667788).withValues(alpha: 0.8),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(left + _vuWidth - _textPainter.width - 7, bottom - _vuHeight + 6),
    );

    final rawPct = (rawLevel * 100).clamp(0.0, 100.0).toStringAsFixed(0);
    _textPainter.text = TextSpan(
      text: 'SIG ${rawPct.padLeft(3)}%',
      style: TextStyle(
        color: const Color(0xFF7FA0B8).withValues(alpha: 0.75),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(left + 7, bottom - 18));

    _textPainter.text = TextSpan(
      text: 'x${drive.toStringAsFixed(1)}',
      style: TextStyle(
        color: const Color(0xFF667788).withValues(alpha: 0.8),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(left + _vuWidth - _textPainter.width - 7, bottom - 18),
    );

    _textPainter.text = const TextSpan(
      text: 'VU',
      style: TextStyle(
        color: Color(0xFF445566),
        fontSize: 7,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        fontFamily: 'RobotoMono',
      ),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(pivotX - _textPainter.width / 2, bottom - 6),
    );
  }

  /// Beat algorithm comparison display — 6 continuous level bars, one per
  /// algorithm.
  ///
  /// Bar height = diagnostic algorithm score (0–3× in the current TV path).
  /// Horizontal guide lines reflect the live detector math from Kotlin:
  ///   red    = mean-threshold variants (`BASS`, `MID`, `BROAD`, `ALL`, `TREB`)
  ///   yellow = `EMA`
  /// Bar glows white when that algorithm fires a beat.
  /// If bars never move, the detector is likely silent or the payload is not
  /// arriving.
  void _renderBeatDebug(Canvas canvas) {
    const numAlgos = 6;
    const barW = 64.0;
    const barGap = 18.0;
    const maxH = 140.0; // height representing ratio = 3.0
    const bottomPad = 100.0;
    const labelH = 32.0;
    const panelPad = 20.0;

    final w = game.size.x;
    final h = game.size.y;
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

    // Background panel
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

    // Diagnostic: session ID, reactor status, raw band levels
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

    // Title + energy readout (proves data is flowing even before beats fire)
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

    // Threshold lines (drawn behind all bars) from live sensitivity math.
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

      // Level bar (continuous, driven by flux/mean ratio)
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

      // Beat flash glow overlay
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

      // Bar border — brightens on flash
      canvas.drawRRect(
        levelRect,
        Paint()
          ..color = color.withValues(
            alpha: (isWinning ? 0.65 : 0.35) + flash * 0.30,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = isWinning || flash > 0.1 ? 2.0 : 1.0,
      );

      // BEAT dot above bar
      if (flash > 0.3) {
        canvas.drawCircle(
          Offset(barLeft + barW / 2, levelTop - 7),
          5.0 * flash,
          Paint()
            ..color = Colors.white.withValues(alpha: flash * 0.9)
            ..style = PaintingStyle.fill,
        );
      }

      if (isWinning) {
        canvas.drawCircle(
          Offset(barLeft + barW / 2, baseY - maxH - 10),
          3.0,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill,
        );
      }

      // Label
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
