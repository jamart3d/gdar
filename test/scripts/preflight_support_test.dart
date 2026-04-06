import 'package:flutter_test/flutter_test.dart';

import '../../scripts/preflight_support.dart';

void main() {
  group('parsePreflightOptions', () {
    test('uses verification mode by default', () {
      final options = parsePreflightOptions(const []);

      expect(options.isRelease, isFalse);
      expect(options.forceRun, isFalse);
      expect(options.runMelos, isTrue);
      expect(options.writeStatus, isTrue);
    });

    test('treats preflight-only as a non-verifying checkup mode', () {
      final options = parsePreflightOptions(const [
        '--preflight-only',
        '--force',
      ]);

      expect(options.isRelease, isFalse);
      expect(options.forceRun, isFalse);
      expect(options.runMelos, isFalse);
      expect(options.writeStatus, isFalse);
    });

    test('keeps release verification enabled for shipit', () {
      final options = parsePreflightOptions(const ['--release', '--force']);

      expect(options.isRelease, isTrue);
      expect(options.forceRun, isTrue);
      expect(options.runMelos, isTrue);
      expect(options.writeStatus, isTrue);
      expect(options.recordStatusOnly, isFalse);
    });

    test('supports writing a fresh PASS receipt without rerunning melos', () {
      final options = parsePreflightOptions(const ['--record-pass']);

      expect(options.isRelease, isFalse);
      expect(options.forceRun, isFalse);
      expect(options.runMelos, isFalse);
      expect(options.writeStatus, isTrue);
      expect(options.recordStatusOnly, isTrue);
    });
  });

  group('detectWindowsToolProcesses', () {
    test('includes flutter_tester and skips the current dart pid', () {
      const csv = '''
"Image Name","PID","Session Name","Session#","Mem Usage"
"dart.exe","111","Console","1","12,344 K"
"dart.exe","222","Console","1","12,344 K"
"flutter_tester.exe","333","Console","1","10,000 K"
"notepad.exe","444","Console","1","2,048 K"
''';

      expect(detectWindowsToolProcesses(csv, selfPid: 111), <String>[
        'dart.exe',
        'flutter_tester.exe',
      ]);
    });
  });
}
