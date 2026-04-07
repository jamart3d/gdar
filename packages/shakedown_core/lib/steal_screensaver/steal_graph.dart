import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        HSLColor,
        FontWeight,
        TextDirection,
        TextPainter,
        TextSpan,
        TextStyle;
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';

part 'steal_graph_constants.dart';
part 'steal_graph_helpers.dart';
part 'steal_graph_render_corner.dart';
part 'steal_graph_render_debug.dart';
part 'steal_graph_render_ekg.dart';

/// Audio reactivity graph with multiple display modes:
/// - corner: 8-bar EQ + beat indicator, anchored bottom-left.
/// - corner_only: corner graph plus VU/scope companion panels.
/// - circular: 8-band radial EQ centered on the logo.
/// - ekg: 150-sample horizontal guitar-tuned EKG line across bottom.
/// - circular_ekg: 150-sample circular guitar-tuned EKG orbiting logo.
/// - vu, scope, beat_debug, off.
class StealGraph extends Component with HasGameReference<StealGame> {
  AudioEnergy energy = const AudioEnergy.zero();
  bool isVisible = false;

  String graphMode = 'off';

  /// Diagnostic fields for beat_debug overlay.
  int? debugSessionId;
  bool debugReactorConnected = false;

  final List<double> _cornerHeights = List.filled(_cornerBarCount, 0.0);
  final List<double> _cornerPeakHeights = List.filled(_cornerBarCount, 0.0);
  final List<double> _circularHeights = List.filled(_bandCount, 0.0);
  final List<double> _circularPeakHeights = List.filled(_bandCount, 0.0);
  final List<double> _ekgHistory = List.filled(_ekgSampleCount, 0.0);

  double _lastEkgVal = 0.0;
  double _ekgAccum = 0.0;
  double _ekgRotation = 0.0;
  HSLColor _ekgHsl = const HSLColor.fromAHSL(1.0, 195.0, 1.0, 0.6);

  double _beatFlash = 0.0;
  final List<double> _algoFlash = List.filled(_algoCount, 0.0);
  final List<double> _algoLevel = List.filled(_algoCount, 0.0);

  double _vuLeft = 0.0;
  double _vuRight = 0.0;
  double _vuPeakLeft = 0.0;
  double _vuPeakRight = 0.0;
  double _vuRawLeft = 0.0;
  double _vuRawRight = 0.0;
  double _vuDrive = 1.0;

  List<double> _scopeWaveform = const [];
  List<double> _scopeWaveformL = const [];
  List<double> _scopeWaveformR = const [];
  double _scopePeak = 0.05;
  double _scopePeakL = 0.05;
  double _scopePeakR = 0.05;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  bool _hasRealStereo = false;

  bool get _isFast => game.config.performanceLevel >= 2;
  bool get _isBalanced => game.config.performanceLevel == 1;

  /// Scale factor so graph renderers work correctly inside the small settings
  /// preview panel. All render functions use [_logicalSize] for positioning
  /// and the canvas is pre-scaled by this factor in [render].
  /// When the game is in a small container (preview panel, ~380–500px wide),
  /// use a 512-px reference so graph elements fill ~75% of the panel instead
  /// of the ~30% they would at the full 1280-px reference.
  double get _graphScale {
    final refWidth = game.size.x < 600 ? 512.0 : 1280.0;
    return (game.size.x / refWidth).clamp(0.25, 2.0);
  }

  Vector2 get _logicalSize => game.size / _graphScale;

  double get _glowSigma {
    if (_isFast) return 0.0;
    if (_isBalanced) return 3.0;
    return 6.0;
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
    if (graphMode == 'corner_only' || graphMode == 'vu') {
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

    if (graphMode == 'ekg' || graphMode == 'circular_ekg') {
      _updateEkgHistory(dt);
    }
    if (graphMode == 'circular_ekg') {
      _ekgRotation += dt * 0.15;
      if (_ekgRotation > 2 * pi) _ekgRotation -= 2 * pi;
    }

    if (graphMode == 'beat_debug') {
      final algos = energy.beatAlgos;
      final levels = energy.algoLevels;
      for (int i = 0; i < _algoFlash.length; i++) {
        final fired = i < algos.length && algos[i];
        if (fired) {
          _algoFlash[i] = 1.0;
        } else {
          _algoFlash[i] = (_algoFlash[i] - _beatFlashDecayPerSec * dt).clamp(
            0.0,
            1.0,
          );
        }
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

    _updateEkgColor(dt);
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    final scale = _graphScale;
    canvas.save();
    canvas.scale(scale, scale);
    switch (graphMode) {
      case 'corner':
        _renderCorner(canvas);
      case 'corner_only':
        _renderCorner(canvas);
        _renderVu(canvas);
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
    canvas.restore();
  }
}
