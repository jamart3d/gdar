import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:shakedown_core/steal_screensaver/steal_background.dart';
import 'package:shakedown_core/steal_screensaver/steal_graph.dart';
import 'package:shakedown_core/steal_screensaver/steal_banner.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('StealGame', () {
    // We use MockDeviceService from your existing helpers
    final mockDevice = MockDeviceService();
    const defaultConfig = StealConfig();

    // FlameTester helps instantiate the game, pump the game loop (dt),
    // and check the component tree lifecycle.
    final stealGameTester = FlameTester<StealGame>(
      () => StealGame(config: defaultConfig, deviceService: mockDevice),
    );

    stealGameTester.testGameWidget(
      'loads core components independently on startup',
      setUp: (game, tester) async {
        // FlameTester automatically handles layout and game.onLoad()
      },
      verify: (game, tester) async {
        // Assert that the game loop registered the expected components
        expect(game.children.whereType<StealBackground>().length, 1);
        expect(game.children.whereType<StealGraph>().length, 1);
        expect(game.children.whereType<StealBanner>().length, 1);
      },
    );

    stealGameTester.testGameWidget(
      'time advances and palette cycle changes configuration',
      setUp: (game, tester) async {
        // Ensure palette cycling is turned on with high speed for the test
        game.updateConfig(
          defaultConfig.copyWith(
            paletteCycle: true,
            paletteTransitionSpeed: 20.0,
          ),
        );
      },
      verify: (game, tester) async {
        final initialPalette = game.config.palette;

        // Pump game loop forward by a large amount of time (100 seconds)
        game.update(100.0);

        // We should have transitioned to a new palette automatically
        expect(game.config.palette, isNot(equals(initialPalette)));
        expect(game.time, greaterThan(0));
      },
    );
  });
}
