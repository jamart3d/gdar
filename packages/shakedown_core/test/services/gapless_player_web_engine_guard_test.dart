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

  test('web pause snapshots the live position locally before JS confirms', () {
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
      contains('double pausedPositionSec = _positionSec;'),
      reason:
          'Pause must begin from the locally cached JS position before '
          'recomputing the paused snapshot.',
    );
    expect(
      script,
      contains('pausedPositionSec = (_positionSec + elapsedSec).clamp('),
      reason:
          'Pause must recompute the live paused position from the last '
          'interpolation anchor so resume does not restart from a stale JS tick.',
    );
    expect(
      script,
      contains('_positionSec = pausedPosition.inMilliseconds / 1000.0;'),
      reason:
          'Pause must commit the snapped position into the local cache used by '
          'the web getter and diagnostics HUD.',
    );
    expect(
      script,
      contains('_lastTickAt = null;'),
      reason:
          'Pause must clear the interpolation anchor after caching the paused '
          'position, or the getter can keep dead-reckoning stale time.',
    );
    expect(
      script,
      contains('_playing = false;'),
      reason:
          'Pause must update the local playing flag immediately rather than '
          'waiting for JS state callbacks.',
    );
  });

  test('web play path schedules post-play resync recovery pulses', () {
    final repoRoot = _findRepoRoot();
    final apiScript = File(
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
    final engineScript = File(
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
      apiScript,
      contains("_schedulePostPlayResyncs(reason: 'play')"),
      reason:
          'Play must schedule follow-up JS state pulls so Dart can recover '
          'from pause/resume callback stalls.',
    );
    expect(
      engineScript,
      contains('void _schedulePostPlayResyncs({required String reason})'),
      reason: 'The web engine must own the deferred post-play resync policy.',
    );
    expect(
      engineScript,
      contains("_resyncFromJsState(reason: '\${reason}_"),
      reason:
          'Deferred play recovery pulses must resync from the live JS state.',
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
