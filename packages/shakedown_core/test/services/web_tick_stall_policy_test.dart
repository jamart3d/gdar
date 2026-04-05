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
}
