import 'dart:convert';
import 'dart:io';

// ── Zero-dependency ANSI logger ─────────────────────────
// Replaces package:logger to avoid slow workspace-wide
// package resolution in the monorepo root.
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';
const _cyan = '\x1B[36m';
const _dim = '\x1B[2m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('ℹ️', _green, msg);
void _step(String msg) => _log('🔹', _cyan, msg);
void _warn(String msg) => _log('⚠️', _yellow, msg);
void _err(String msg) => _log('❌', _red, msg);
void _debug(String msg) => _log('  ', _dim, msg);

/// Unified Preflight & Verification script for GDAR.
///
/// Handles the entire pre-build pipeline in one shot:
/// 1. Detects host platform (WINDOWS_10 or CHROMEBOOK).
/// 2. Verifies toolchain (git, dart, flutter, firebase).
/// 3. Checks for hung processes.
/// 4. Smart-skip: compares verification_status.json SHA
///    against current HEAD. Runs melos suite only if needed.
/// 5. Updates verification_status.json on success.
///
/// Exit codes:
///   0 = success (stdout ends with WINDOWS_10:VERIFIED
///       or CHROMEBOOK:STOP)
///   1 = toolchain missing or melos suite failed
void main(List<String> args) async {
  final isRelease = args.contains('--release');
  final forceRun = args.contains('--force');

  _info('--- Starting GDAR Preflight ---');

  // ── Step 1: Detect Platform ──────────────────────────
  _step('Step 1: Detecting Host Class...');
  final platform = _detectPlatform();
  _info('Host: $platform');

  // ── Step 2: Toolchain ────────────────────────────────
  _step('Step 2: Checking Toolchain...');
  final commands = ['git', 'dart', 'flutter'];
  if (isRelease) commands.add('firebase');

  for (final cmd in commands) {
    if (!await _commandExists(cmd)) {
      _err('FAIL: Command "$cmd" not found in PATH.');
      exit(1);
    }
  }
  _info('Toolchain verified: ${commands.join(", ")}');

  // ── Step 3: Process Hygiene ──────────────────────────
  _step('Step 3: Checking Process Hygiene...');
  final hungProcesses = await _findHungProcesses();
  if (hungProcesses.isNotEmpty) {
    _warn(
      'Warning: Hung processes detected: '
      '${hungProcesses.join(", ")}',
    );
    _warn(
      'Consider running "melos run clean" before a '
      'production build.',
    );
  } else {
    _info('No hung Dart/Flutter processes detected.');
  }

  // ── Chromebook early exit ────────────────────────────
  if (platform == 'CHROMEBOOK') {
    _info('--- Preflight Complete [CHROMEBOOK:STOP] ---');
    // ignore: avoid_print
    print('CHROMEBOOK:STOP');
    return;
  }

  // ── Step 4: Smart Skip Check ─────────────────────────
  _step('Step 4: Checking verification status...');
  final shouldRunMelos =
      forceRun || await _shouldRunMelos();
  if (forceRun) {
    _info('--force flag set — skipping smart-skip.');
  }

  if (shouldRunMelos) {
    _info('Verification stale or missing — running '
        'melos health suite...');

    // Format → Analyze → Test (sequential)
    final steps = [
      ['melos', 'run', 'format'],
      ['melos', 'run', 'analyze'],
      ['melos', 'run', 'test'],
    ];

    for (final step in steps) {
      final label = step.join(' ');
      _info('Running: $label');
      final process = await Process.start(
        step[0],
        step.sublist(1),
        runInShell: true,
      );

      // Drain both pipes AND wait for exit concurrently.
      // Using Future.wait prevents OS pipe-buffer deadlock
      // on Windows when a melos step writes >4KB to stderr.
      final results = await Future.wait([
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) => _debug(line)),
        process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) => _err(line)),
        process.exitCode,
      ]);

      final exitCode = results[2] as int;
      if (exitCode != 0) {
        _err('FAIL: $label exited with $exitCode');
        exit(1);
      }
      _info('PASS: $label');
    }

    // Update verification_status.json
    await _updateVerificationStatus();
    _info('verification_status.json updated.');
  } else {
    _info(
      'Verification current — skipping melos suite.',
    );
  }

  _info('--- Preflight Complete [WINDOWS_10:VERIFIED] ---');
  // ignore: avoid_print
  print('WINDOWS_10:VERIFIED');
}

// ── Helpers ──────────────────────────────────────────────

String _detectPlatform() {
  return Platform.isWindows ? 'WINDOWS_10' : 'CHROMEBOOK';
}

Future<bool> _commandExists(String cmd) async {
  final checkCmd = Platform.isWindows ? 'where' : 'which';
  final result = await Process.run(checkCmd, [cmd]);
  return result.exitCode == 0;
}

Future<List<String>> _findHungProcesses() async {
  final hung = <String>[];
  if (Platform.isWindows) {
    final selfPid = pid.toString();
    final result = await Process.run('tasklist', []);
    final output = result.stdout.toString();
    if (output.contains('flutter.exe')) {
      hung.add('flutter');
    }
    // Filter out our own dart.exe process
    if (output.contains('dart.exe')) {
      final lines = output.split('\n').where(
        (l) => l.contains('dart.exe') && !l.contains(selfPid),
      );
      if (lines.isNotEmpty) hung.add('dart');
    }
  }
  return hung;
}

/// Returns true if the melos health suite needs to run.
///
/// Compares the SHA in verification_status.json against
/// the current git HEAD. Skips only if both match AND
/// the status is exactly "PASS".
Future<bool> _shouldRunMelos() async {
  final statusFile = File(
    '.agent/notes/verification_status.json',
  );
  if (!statusFile.existsSync()) return true;

  try {
    final data = jsonDecode(statusFile.readAsStringSync())
        as Map<String, dynamic>;
    final lastSha =
        data['last_verification_commit'] as String? ?? '';
    final status = data['status'] as String? ?? '';

    if (status != 'PASS') {
      _info(
        'Status is "$status" (not PASS) — '
        'suite required.',
      );
      return true;
    }

    final headResult = await Process.run(
      'git',
      ['rev-parse', 'HEAD'],
    );
    final currentSha =
        headResult.stdout.toString().trim();

    if (lastSha == currentSha) {
      _info(
        'SHA match: $currentSha — skip eligible.',
      );
      return false;
    }

    _info(
      'SHA mismatch: HEAD=$currentSha vs '
      'verified=$lastSha — suite required.',
    );
    return true;
  } catch (e) {
    _warn(
      'Could not parse verification_status.json: $e',
    );
    return true;
  }
}

/// Writes a fresh PASS record to
/// verification_status.json.
Future<void> _updateVerificationStatus() async {
  final headResult = await Process.run(
    'git',
    ['rev-parse', 'HEAD'],
  );
  final sha = headResult.stdout.toString().trim();

  final data = {
    'last_verification_commit': sha,
    'status': 'PASS',
    'score': 100,
    'results': {
      'analyze': 'SUCCESS',
      'test': 'SUCCESS (All tests passed)',
      'format': 'SUCCESS (Clean workspace)',
    },
    'timestamp': DateTime.now().toIso8601String(),
  };

  final file = File(
    '.agent/notes/verification_status.json',
  );
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(data),
  );
}
