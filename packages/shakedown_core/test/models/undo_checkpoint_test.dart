import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/undo_checkpoint.dart';

void main() {
  group('UndoCheckpoint', () {
    test('isExpiredAt stays false through the 10 second window', () {
      final createdAt = DateTime(2026, 4, 7, 12, 0, 0);
      final checkpoint = UndoCheckpoint(
        sourceId: 'gd77-05-08.sbd.1234',
        showDate: '1977-05-08',
        trackIndex: 1,
        position: const Duration(seconds: 42),
        title: '1977-05-08 Barton Hall',
        createdAt: createdAt,
      );

      expect(
        checkpoint.isExpiredAt(createdAt.add(const Duration(seconds: 10))),
        isFalse,
      );
    });

    test('isExpiredAt becomes true after 10 seconds have passed', () {
      final createdAt = DateTime(2026, 4, 7, 12, 0, 0);
      final checkpoint = UndoCheckpoint(
        sourceId: 'gd77-05-08.sbd.1234',
        showDate: '1977-05-08',
        trackIndex: 1,
        position: const Duration(seconds: 42),
        title: '1977-05-08 Barton Hall',
        createdAt: createdAt,
      );

      expect(
        checkpoint.isExpiredAt(createdAt.add(const Duration(seconds: 11))),
        isTrue,
      );
    });
  });
}
