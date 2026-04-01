import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/steal_screensaver/steal_background.dart';

void main() {
  group('TrailSnapshot', () {
    test('lerp correctly interpolates position, size, and color', () {
      const startPos = ui.Offset(0.0, 0.0);
      const endPos = ui.Offset(10.0, 10.0);
      const startSize = 100.0;
      const endSize = 200.0;
      const startColor = ui.Color(0xFFFF0000); // Red
      const endColor = ui.Color(0xFF0000FF); // Blue

      const a = TrailSnapshot(startPos, startSize, startColor);
      const b = TrailSnapshot(endPos, endSize, endColor);

      // Test at t=0.0
      final t0 = TrailSnapshot.lerp(a, b, 0.0);
      expect(t0.pos, equals(startPos));
      expect(t0.size, equals(startSize));
      expect(t0.color, equals(startColor));

      // Test at t=1.0
      final t1 = TrailSnapshot.lerp(a, b, 1.0);
      expect(t1.pos, equals(endPos));
      expect(t1.size, equals(endSize));
      expect(t1.color, equals(endColor));

      // Test at t=0.5
      final t05 = TrailSnapshot.lerp(a, b, 0.5);
      expect(t05.pos, equals(const ui.Offset(5.0, 5.0)));
      expect(t05.size, equals(150.0));
      // Red (FF0000) to Blue (0000FF) at 0.5 should be Purple (approx 800080 or middle)
      expect((t05.color.r * 255).round(), inInclusiveRange(120, 135));
      expect((t05.color.b * 255).round(), inInclusiveRange(120, 135));
      expect((t05.color.g * 255).round(), equals(0));
    });
  });
}
