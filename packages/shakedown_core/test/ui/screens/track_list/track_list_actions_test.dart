import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/ui/screens/track_list/track_list_actions.dart';

void main() {
  group('resolveTrackTapAction', () {
    test('returns play-on-tap menu when play on tap is disabled', () {
      expect(
        resolveTrackTapAction(
          playOnTap: false,
          currentSourceId: 'source-a',
          sourceId: 'source-a',
        ),
        TrackTapActionKind.showPlayOnTapMenu,
      );
    });

    test('returns seek when tapping the current source', () {
      expect(
        resolveTrackTapAction(
          playOnTap: true,
          currentSourceId: 'source-a',
          sourceId: 'source-a',
        ),
        TrackTapActionKind.seekCurrentSource,
      );
    });

    test('returns play from header when tapping a different source', () {
      expect(
        resolveTrackTapAction(
          playOnTap: true,
          currentSourceId: 'source-a',
          sourceId: 'source-b',
        ),
        TrackTapActionKind.playFromHeader,
      );
    });

    test('returns play from header when no current source is active', () {
      expect(
        resolveTrackTapAction(
          playOnTap: true,
          currentSourceId: null,
          sourceId: 'source-b',
        ),
        TrackTapActionKind.playFromHeader,
      );
    });
  });
}
