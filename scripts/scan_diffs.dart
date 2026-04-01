import 'dart:io';

// ── Zero-dependency ANSI logger ─────────────────────────
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('ℹ️', _green, msg);
void _warn(String msg) => _log('⚠️', _yellow, msg);
void _err(String msg) => _log('❌', _red, msg);
// Configure a beautiful, colorful logger for the micro-scanner output.

Future<void> main() async {
  // Collect modified/added files (staged or unstaged)
  final result = await Process.run('git', ['diff', '--name-only', 'HEAD']);

  if (result.exitCode != 0) {
    _err('Git command failed: ${result.stderr}');
    exit(1);
  }

  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    _info('No changed files found. Micro-scanner skipping.');
    exit(0);
  }

  // Filter for only .dart files
  final changedFiles = output
      .split('\n')
      .map((line) => line.trim())
      .where((file) => file.endsWith('.dart'))
      .toList();

  if (changedFiles.isEmpty) {
    _info('No changed Dart files found. Micro-scanner skipping.');
    exit(0);
  }

  _info(
    'Scanning ${changedFiles.length} pending file(s) for styling constraints...',
  );

  int violations = 0;

  for (final filePath in changedFiles) {
    final file = File(filePath);

    // Skip if file was deleted
    if (!await file.exists()) {
      continue;
    }

    final lines = await file.readAsLines();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Target 1: withOpacity() - Modern syntax requirement
      if (line.contains('withOpacity(')) {
        _warn(
          'Legacy \'withOpacity()\' found in $filePath:${i + 1}\n'
          '   -> Please use the modern \'.withValues()\' method.',
        );
        violations++;
      }

      // Target 2: Colors.* - Breaks multi-platform guidelines
      if (line.contains('Colors.')) {
        _warn(
          'Hardcoded \'Colors.\' found in $filePath:${i + 1}\n'
          '   -> Please use semantic theme variables or styles to support Dark Mode / Fruit.',
        );
        violations++;
      }
    }
  }

  if (violations > 0) {
    _err(
      'Micro-Scanner failed! Found $violations violation(s).\n'
      '   Please fix the listed items to pass the checkup workflow.',
    );
    exit(1);
  }

  _info(
    'Micro-Scanner passed. No styling violations found in pending files.',
  );
  exit(0);
}
