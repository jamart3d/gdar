import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native GaplessPlayer exposes an empty playBlockedStream', () async {
    final player = GaplessPlayer(useWebGaplessEngine: false);

    await expectLater(player.playBlockedStream, emitsDone);

    await player.dispose();
  });
}
