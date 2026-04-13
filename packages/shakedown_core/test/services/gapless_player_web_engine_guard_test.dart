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

  test('web interpolation suppresses buffering/loading handoffs', () {
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
      contains('ProcessingState.buffering'),
      reason:
          'Interpolation must stay disabled while the web engine is handing '
          'off state through buffering.',
    );
    expect(
      script,
      contains('ProcessingState.loading'),
      reason:
          'Interpolation must stay disabled while the web engine is loading.',
    );
  });

  test('web pause and stop paths cancel the interpolation timer', () {
    final repoRoot = _findRepoRoot();
    final script = File(
      p.join(
        repoRoot,
        'packages',
        'shakedown_core',
        'lib',
        'services',
        'gapless_player',
        'gapless_player_web_api.dart',
      ),
    ).readAsStringSync();

    expect(
      script,
      contains('Future<void> pause() async'),
      reason: 'Pause should remain the local stop point for interpolation.',
    );
    expect(
      script,
      contains('Future<void> stop() async'),
      reason: 'Stop should remain the local stop point for interpolation.',
    );
    expect(
      script,
      contains('_stopInterpolationTimer();'),
      reason:
          'Pause and stop need to cancel the Dart interpolation timer before '
          'JS callbacks catch up.',
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
