import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/gapless_player/web_tick_stall_policy.dart';

void main() {
  test(
    'resyncs only when visible, playing, and tick gap exceeds threshold',
    () {
      final now = DateTime(2026, 4, 5, 12);

      expect(
        WebTickStallPolicy.shouldResync(
          playing: true,
          visible: true,
          lastTickAt: now.subtract(const Duration(seconds: 3)),
          stallThreshold: const Duration(seconds: 2),
          now: now,
        ),
        isTrue,
      );

      expect(
        WebTickStallPolicy.shouldResync(
          playing: false,
          visible: true,
          lastTickAt: now.subtract(const Duration(seconds: 3)),
          stallThreshold: const Duration(seconds: 2),
          now: now,
        ),
        isFalse,
      );

      expect(
        WebTickStallPolicy.shouldResync(
          playing: true,
          visible: false,
          lastTickAt: now.subtract(const Duration(seconds: 3)),
          stallThreshold: const Duration(seconds: 2),
          now: now,
        ),
        isFalse,
      );

      expect(
        WebTickStallPolicy.shouldResync(
          playing: true,
          visible: true,
          lastTickAt: now.subtract(const Duration(seconds: 1)),
          stallThreshold: const Duration(seconds: 2),
          now: now,
        ),
        isFalse,
      );

      expect(
        WebTickStallPolicy.shouldResync(
          playing: true,
          visible: true,
          lastTickAt: null,
          stallThreshold: const Duration(seconds: 2),
          now: now,
        ),
        isFalse,
      );
    },
  );

  group('shouldInterpolate', () {
    final now = DateTime(2026, 4, 13, 10);
    const minGap = Duration(milliseconds: 250);

    test('returns true when playing and tick overdue', () {
      expect(
        WebTickStallPolicy.shouldInterpolate(
          playing: true,
          lastTickAt: now.subtract(const Duration(milliseconds: 300)),
          minGapBeforeInterpolate: minGap,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false when not playing', () {
      expect(
        WebTickStallPolicy.shouldInterpolate(
          playing: false,
          lastTickAt: now.subtract(const Duration(milliseconds: 300)),
          minGapBeforeInterpolate: minGap,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when lastTickAt is null', () {
      expect(
        WebTickStallPolicy.shouldInterpolate(
          playing: true,
          lastTickAt: null,
          minGapBeforeInterpolate: minGap,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when tick was recent (under minGap)', () {
      expect(
        WebTickStallPolicy.shouldInterpolate(
          playing: true,
          lastTickAt: now.subtract(const Duration(milliseconds: 100)),
          minGapBeforeInterpolate: minGap,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns true exactly at min gap boundary', () {
      expect(
        WebTickStallPolicy.shouldInterpolate(
          playing: true,
          lastTickAt: now.subtract(minGap),
          minGapBeforeInterpolate: minGap,
          now: now,
        ),
        isTrue,
      );
    });
  });
}
