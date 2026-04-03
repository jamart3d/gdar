part of 'steal_graph.dart';

extension _StealGraphHelpers on StealGraph {
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

    final x = nx.clamp(0.0, 1.0) * amp;
    final y = -ny.clamp(0.0, 1.0) * amp;
    return Offset(x, y);
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
    _ekgHsl = HSLColor.lerp(_ekgHsl, target, (dt * 1.5).clamp(0.0, 1.0))!;
  }

  /// Drives the EKG history at a fixed sample rate so scroll speed is
  /// consistent regardless of device frame rate.
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

  void _updateVuLevels(double dt) {
    double targetL;
    double targetR;

    if (energy.waveformL.isNotEmpty && energy.waveformR.isNotEmpty) {
      _hasRealStereo = true;
      _vuDrive = 2.5;
      _vuRawLeft = _rms(energy.waveformL).clamp(0.0, 1.0);
      _vuRawRight = _rms(energy.waveformR).clamp(0.0, 1.0);
      targetL = (_vuRawLeft * _vuDrive).clamp(0.0, 1.0);
      targetR = (_vuRawRight * _vuDrive).clamp(0.0, 1.0);
    } else {
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

  /// Smooth the 8-band FFT data + beat for corner graph rendering.
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
}
