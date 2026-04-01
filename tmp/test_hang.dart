// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  print('=== Hang Detector ===');

  print('[${DateTime.now()}] Testing: where git');
  var r = await Process.run('where', ['git']);
  print('  exit: ${r.exitCode}');

  print('[${DateTime.now()}] Testing: where dart');
  r = await Process.run('where', ['dart']);
  print('  exit: ${r.exitCode}');

  print('[${DateTime.now()}] Testing: where flutter');
  r = await Process.run('where', ['flutter']);
  print('  exit: ${r.exitCode}');

  print('[${DateTime.now()}] Testing: where firebase');
  r = await Process.run('where', ['firebase']);
  print('  exit: ${r.exitCode}');

  print('[${DateTime.now()}] Testing: tasklist');
  r = await Process.run('tasklist', []);
  print('  exit: ${r.exitCode} (${r.stdout.toString().length} chars)');

  print('[${DateTime.now()}] Testing: git rev-parse HEAD');
  r = await Process.run('git', ['rev-parse', 'HEAD']);
  print('  exit: ${r.exitCode} sha: ${r.stdout.toString().trim()}');

  print('[${DateTime.now()}] Testing: melos run format (Process.start)');
  final p = await Process.start('melos', ['run', 'format'], runInShell: true);
  print('  started PID: ${p.pid}');

  // Drain with timeout
  p.stdout.listen((data) => stdout.add(data));
  p.stderr.listen((data) => stderr.add(data));

  final exitCode = await p.exitCode.timeout(
    const Duration(seconds: 120),
    onTimeout: () {
      print('TIMEOUT: melos run format exceeded 120s');
      p.kill();
      return -1;
    },
  );
  print('[${DateTime.now()}] melos format exit: $exitCode');

  print('=== Done ===');
}
