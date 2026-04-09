import 'dart:math' as math;
import 'dart:ui';

double softClip(double value, {double gain = 50.0}) {
  return math.atan(value * gain) / (math.pi / 2);
}

List<Offset> buildWaveformPoints({
  required List<double> waveform,
  required double startX,
  required double availableWidth,
  required double centerY,
  required double laneHeight,
  required double Function(double value) normalize,
}) {
  if (waveform.isEmpty) {
    return const [];
  }

  final halfHeight = laneHeight / 2;
  if (waveform.length == 1) {
    return [Offset(startX, centerY - normalize(waveform.first) * halfHeight)];
  }

  return List<Offset>.generate(waveform.length, (index) {
    final x = startX + (index / (waveform.length - 1)) * availableWidth;
    final y = centerY - normalize(waveform[index]) * halfHeight;
    return Offset(x, y);
  });
}

Path buildWaveformPath({
  required List<double> waveform,
  required double startX,
  required double availableWidth,
  required double centerY,
  required double laneHeight,
  required double Function(double value) normalize,
}) {
  final points = buildWaveformPoints(
    waveform: waveform,
    startX: startX,
    availableWidth: availableWidth,
    centerY: centerY,
    laneHeight: laneHeight,
    normalize: normalize,
  );

  final path = Path();
  if (points.isEmpty) {
    return path;
  }

  path.moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path;
}

List<Offset> synthOscilloscopePoints({
  required List<double> bands,
  required double time,
  required double startX,
  required double availableWidth,
  required double centerY,
  required double scopeHeight,
  int numPoints = 128,
  double windowSeconds = 4.0,
  List<double> frequencies = const [0.2, 0.4, 0.7, 1.1, 1.6, 2.25, 3.0, 4.0],
}) {
  if (numPoints <= 0) {
    return const [];
  }

  final amps = List<double>.generate(
    frequencies.length,
    (index) => index < bands.length ? softClip(bands[index] * 3.0) : 0.0,
  );

  return List<Offset>.generate(numPoints, (index) {
    final x = numPoints == 1
        ? startX
        : startX + (index / (numPoints - 1)) * availableWidth;
    final tx = numPoints == 1
        ? time
        : time - windowSeconds + (index / (numPoints - 1)) * windowSeconds;

    var value = 0.0;
    for (int bandIndex = 0; bandIndex < amps.length; bandIndex++) {
      value +=
          amps[bandIndex] * math.sin(2 * math.pi * frequencies[bandIndex] * tx);
    }
    value = (value / 4.0).clamp(-1.0, 1.0);

    return Offset(x, centerY - value * (scopeHeight / 2));
  });
}

int activeLedSegmentIndex({required double level, required int segmentCount}) {
  if (segmentCount <= 0) {
    return 0;
  }
  return (level.clamp(0.0, 1.0) * (segmentCount - 1)).round();
}

int peakLedSegmentIndex({
  required double peakLevel,
  required int segmentCount,
  double threshold = 0.02,
}) {
  if (peakLevel <= threshold) {
    return -1;
  }
  return activeLedSegmentIndex(level: peakLevel, segmentCount: segmentCount);
}

double normalizeLoopAngle(double angle) {
  const tau = math.pi * 2;
  final mod = angle % tau;
  return mod < 0 ? mod + tau : mod;
}
