import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';

void main() {
  group('computeFruitFloatingNowPlayingBottomOffset', () {
    test('returns zero when sticky now playing is enabled', () {
      final offset = computeFruitFloatingNowPlayingBottomOffset(
        stickyNowPlaying: true,
        hasCurrentTrack: true,
        showCompactHud: true,
        scaleFactor: 1.0,
        bottomSafeArea: 0.0,
        measuredCardHeight: 220.0,
      );

      expect(offset, 0.0);
    });

    test('returns zero when there is no current track', () {
      final offset = computeFruitFloatingNowPlayingBottomOffset(
        stickyNowPlaying: false,
        hasCurrentTrack: false,
        showCompactHud: true,
        scaleFactor: 1.0,
        bottomSafeArea: 0.0,
        measuredCardHeight: 220.0,
      );

      expect(offset, 0.0);
    });

    test('uses HUD-aware fallback height before measurement is available', () {
      final offset = computeFruitFloatingNowPlayingBottomOffset(
        stickyNowPlaying: false,
        hasCurrentTrack: true,
        showCompactHud: true,
        scaleFactor: 1.0,
        bottomSafeArea: 0.0,
        measuredCardHeight: 0.0,
      );

      expect(offset, 221.0);
    });

    test('prefers measured card height when it is larger than fallback', () {
      final offset = computeFruitFloatingNowPlayingBottomOffset(
        stickyNowPlaying: false,
        hasCurrentTrack: true,
        showCompactHud: true,
        scaleFactor: 1.0,
        bottomSafeArea: 18.0,
        measuredCardHeight: 240.0,
      );

      expect(offset, 275.0);
    });
  });
}
