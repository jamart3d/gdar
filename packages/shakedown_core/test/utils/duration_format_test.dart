import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/utils/duration_format.dart';

void main() {
  group('formatDuration', () {
    test('formats minute-second durations with zero padding', () {
      expect(formatDuration(const Duration(seconds: 5)), '00:05');
      expect(formatDuration(const Duration(minutes: 2, seconds: 3)), '02:03');
    });

    test('formats hour durations without padding the hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('parseDuration', () {
    test('parses hour minute second strings', () {
      expect(
        parseDuration('1:02:03'),
        const Duration(hours: 1, minutes: 2, seconds: 3),
      );
    });

    test('parses minute second strings', () {
      expect(parseDuration('02:03'), const Duration(minutes: 2, seconds: 3));
    });

    test('returns zero for malformed values', () {
      expect(parseDuration('abc:def'), Duration.zero);
    });
  });
}
