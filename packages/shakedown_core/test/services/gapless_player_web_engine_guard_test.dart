import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('web engine registration guards optional onPlayBlocked callback', () {
    final repoRoot = _findRepoRoot();
    final script = File(
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

    expect(
      script,
      contains("hasOwnProperty('onPlayBlocked'.toJS)"),
      reason:
          'Web startup must not assume older deployed JS engines already expose '
          'onPlayBlocked(cb).',
    );
  });
}

String _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final packageDir = Directory(
      p.join(current.path, 'packages', 'shakedown_core', 'lib'),
    );
    if (packageDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Unable to locate repo root containing packages/shakedown_core from '
        '${Directory.current.path}.',
      );
    }
    current = parent;
  }
}
