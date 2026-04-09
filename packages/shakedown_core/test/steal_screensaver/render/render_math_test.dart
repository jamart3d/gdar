import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/steal_screensaver/render/render_math.dart';

void main() {
  group('softClip', () {
    test('returns zero at the origin and stays symmetric', () {
      expect(softClip(0), 0);
      expect(softClip(0.25), closeTo(-softClip(-0.25), 1e-9));
    });

    test('approaches +/-1 as values grow', () {
      expect(softClip(1000), closeTo(1, 1e-4));
      expect(softClip(-1000), closeTo(-1, 1e-4));
    });
  });

  group('buildWaveformPoints', () {
    test('maps waveform samples into evenly spaced points', () {
      final points = buildWaveformPoints(
        waveform: const [-1, 0, 1],
        startX: 10,
        availableWidth: 20,
        centerY: 50,
        laneHeight: 40,
        normalize: (value) => value,
      );

      expect(points, const [Offset(10, 70), Offset(20, 50), Offset(30, 30)]);
    });

    test('keeps a single-sample waveform anchored to startX', () {
      final points = buildWaveformPoints(
        waveform: const [0.5],
        startX: 8,
        availableWidth: 99,
        centerY: 30,
        laneHeight: 20,
        normalize: (value) => value,
      );

      expect(points, const [Offset(8, 25)]);
    });
  });

  group('synthOscilloscopePoints', () {
    test('produces a deterministic line within the scope bounds', () {
      final points = synthOscilloscopePoints(
        bands: const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
        time: 2.5,
        startX: 5,
        availableWidth: 50,
        centerY: 20,
        scopeHeight: 10,
        numPoints: 5,
      );

      expect(points, hasLength(5));
      expect(points.first.dx, 5);
      expect(points.last.dx, 55);
      for (final point in points) {
        expect(point.dy, inInclusiveRange(15, 25));
      }
    });
  });

  group('LED helpers', () {
    test('clamps active and peak segment indices', () {
      expect(activeLedSegmentIndex(level: -1, segmentCount: 16), 0);
      expect(activeLedSegmentIndex(level: 1, segmentCount: 16), 15);
      expect(activeLedSegmentIndex(level: 0.5, segmentCount: 16), 8);

      expect(peakLedSegmentIndex(peakLevel: 0.01, segmentCount: 16), -1);
      expect(peakLedSegmentIndex(peakLevel: 1.2, segmentCount: 16), 15);
    });
  });

  group('normalizeLoopAngle', () {
    test('wraps values into the 0..tau interval', () {
      const tau = math.pi * 2;
      expect(normalizeLoopAngle(0), 0);
      expect(normalizeLoopAngle(tau), 0);
      expect(
        normalizeLoopAngle(-math.pi / 2),
        closeTo(tau - math.pi / 2, 1e-9),
      );
    });
  });
}
