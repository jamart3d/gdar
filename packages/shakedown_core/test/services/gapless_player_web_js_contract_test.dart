import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
