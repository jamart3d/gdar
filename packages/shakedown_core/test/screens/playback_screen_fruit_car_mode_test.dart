import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';

void main() {
  group('computeFruitCarModePendingCue', () {
    test('shows pending cue while loading', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: true,
          isBuffering: false,
          bufferedPositionMs: 0,
          positionMs: 0,
          durationMs: 0,
        ),
        isTrue,
      );
    });

    test('hides pending cue when enough buffer headroom exists', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: false,
          isBuffering: false,
          bufferedPositionMs: 9000,
          positionMs: 8000,
          durationMs: 20000,
        ),
        isFalse,
      );
    });

    test('shows pending cue when headroom is too thin', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: false,
          isBuffering: false,
          bufferedPositionMs: 8200,
          positionMs: 8000,
          durationMs: 20000,
        ),
        isTrue,
      );
    });
  });

  group('computeFruitCarModeProgressMetrics', () {
    test('clamps progress values into valid ranges', () {
      final metrics = computeFruitCarModeProgressMetrics(
        position: const Duration(seconds: 15),
        buffered: const Duration(seconds: 40),
        total: const Duration(seconds: 30),
      );

      expect(metrics.totalMs, 30000);
      expect(metrics.positionMs, 15000);
      expect(metrics.bufferedMs, 30000);
      expect(metrics.progress, 0.5);
      expect(metrics.bufferedProgress, 1.0);
    });
  });

  group('computeFruitCarModeHeadroomFill', () {
    test('treats 30 seconds as full scale', () {
      expect(computeFruitCarModeHeadroomFill(headroom: Duration.zero), 0.0);
      expect(
        computeFruitCarModeHeadroomFill(headroom: const Duration(seconds: 30)),
        1.0,
      );
    });

    test('scales linearly within the fixed 30 second tank', () {
      expect(
        computeFruitCarModeHeadroomFill(headroom: const Duration(seconds: 15)),
        closeTo(0.5, 0.0001),
      );
    });
  });

  group('computeFruitCarModeNextTrackFill', () {
    test('normalizes next-track readiness against the next file total', () {
      expect(
        computeFruitCarModeNextTrackFill(
          nextBuffered: const Duration(seconds: 15),
          nextTotal: const Duration(seconds: 30),
        ),
        closeTo(0.5, 0.0001),
      );
      expect(
        computeFruitCarModeNextTrackFill(
          nextBuffered: const Duration(seconds: 45),
          nextTotal: const Duration(seconds: 30),
        ),
        1.0,
      );
    });

    test('treats unknown next-file total as binary loaded state', () {
      expect(
        computeFruitCarModeNextTrackFill(
          nextBuffered: Duration.zero,
          nextTotal: null,
        ),
        0.0,
      );
      expect(
        computeFruitCarModeNextTrackFill(
          nextBuffered: const Duration(seconds: 1),
          nextTotal: null,
        ),
        1.0,
      );
    });
  });

  group('parseFruitCarModeDurationText', () {
    test('parses signed unit values used by HD', () {
      expect(
        parseFruitCarModeDurationText('+143ms'),
        const Duration(milliseconds: 143),
      );
      expect(parseFruitCarModeDurationText('+8s'), const Duration(seconds: 8));
    });

    test('parses clock values used by NXT', () {
      expect(
        parseFruitCarModeDurationText('00:42'),
        const Duration(seconds: 42),
      );
      expect(
        parseFruitCarModeDurationText('01:02:03'),
        const Duration(hours: 1, minutes: 2, seconds: 3),
      );
    });

    test('returns null for placeholders', () {
      expect(parseFruitCarModeDurationText('--'), isNull);
    });
  });
}
