import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verification_status_support.dart';

void main() {
  group('buildPassVerificationStatus', () {
    test('marks the current head as PASS with clean verification results', () {
      final timestamp = DateTime.parse('2026-04-07T10:11:12.000Z');

      final status = buildPassVerificationStatus(
        sha: 'abc123',
        timestamp: timestamp,
      );

      expect(status['last_verification_commit'], 'abc123');
      expect(status['status'], 'PASS');
      expect(status['score'], 100);
      expect(status['results'], {
        'analyze': 'SUCCESS',
        'test': 'SUCCESS (All tests passed)',
        'format': 'SUCCESS (Clean workspace)',
      });
      expect(status['timestamp'], timestamp.toIso8601String());
    });
  });

  group('buildSavedVerificationStatus', () {
    test('marks a newly saved head as unverified for smart-skip purposes', () {
      final timestamp = DateTime.parse('2026-04-07T10:11:12.000Z');

      final status = buildSavedVerificationStatus(
        sha: 'def456',
        timestamp: timestamp,
      );

      expect(status['last_verification_commit'], 'def456');
      expect(status['status'], 'SAVED');
      expect(status['score'], 0);
      expect(status['results'], {
        'analyze': 'STALE (New commit saved without fresh verification)',
        'test': 'STALE (New commit saved without fresh verification)',
        'format': 'STALE (New commit saved without fresh verification)',
      });
      expect(status['timestamp'], timestamp.toIso8601String());
    });
  });
}
