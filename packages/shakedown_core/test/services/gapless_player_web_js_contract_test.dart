import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Regression: the early _processingStateController.add inside _onJsStateChange
  // (before _playing is updated) caused the processingState stream to fire twice
  // per state tick, invoking _listenForProcessingState twice on ProcessingState
  // .completed and launching two concurrent playRandomShow() futures.
  // After the fix, there must be exactly two adds in the file:
  //   1. the error-handler path (_onJsError)
  //   2. the end of _onJsStateChange (after all fields are updated)
  test(
    '_processingStateController.add appears exactly twice in web engine '
    '(error handler + single end-of-tick emission)',
    () {
      final repoRoot = _findRepoRoot();
      final source = File(
        p.join(
          repoRoot,
          'packages',
          'shakedown_core',
          'lib',
          'services',
          'gapless_player',
          'gapless_player_web_engine.dart',
        ),
      ).readAsStringSync();

      final count =
          '_processingStateController.add'.allMatches(source).length;
      expect(
        count,
        2,
        reason:
            'Expected exactly 2 _processingStateController.add calls '
            '(error path + end-of-tick). An extra early emission before '
            '_playing is updated causes double-fire of '
            '_listenForProcessingState on show completion.',
      );
    },
  );

  test('all web audio engines expose onPlayBlocked callback registration', () {
    final repoRoot = _findRepoRoot();
    final webRoot = p.join(repoRoot, 'apps', 'gdar_web', 'web');
    const engineFiles = <String>[
      'gapless_audio_engine.js',
      'html5_audio_engine.js',
      'hybrid_audio_engine.js',
      'passive_audio_engine.js',
    ];

    for (final engineFile in engineFiles) {
      final script = File(p.join(webRoot, engineFile)).readAsStringSync();
      expect(
        script,
        contains('onPlayBlocked: function (cb)'),
        reason:
            '$engineFile must expose onPlayBlocked(cb) for GaplessPlayer web interop.',
      );
    }
  });
}

String _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final webDir = Directory(p.join(current.path, 'apps', 'gdar_web', 'web'));
    if (webDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Unable to locate repo root containing apps/gdar_web/web from ${Directory.current.path}.',
      );
    }
    current = parent;
  }
}
