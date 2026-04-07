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
}
