import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

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

  logger.i('--- Starting GDAR Preflight ---');

  // ── Step 1: Detect Platform ──────────────────────────
  logger.i('Step 1: Detecting Host Class...');
  final platform = _detectPlatform();
  logger.i('Host: $platform');

  // ── Step 2: Toolchain ────────────────────────────────
  logger.i('Step 2: Checking Toolchain...');
  final commands = ['git', 'dart', 'flutter'];
  if (isRelease) commands.add('firebase');

  for (final cmd in commands) {
    if (!await _commandExists(cmd)) {
      logger.e('FAIL: Command "$cmd" not found in PATH.');
      exit(1);
    }
  }
  logger.i('Toolchain verified: ${commands.join(", ")}');

  // ── Step 3: Process Hygiene ──────────────────────────
  logger.i('Step 3: Checking Process Hygiene...');
  final hungProcesses = await _findHungProcesses();
  if (hungProcesses.isNotEmpty) {
    logger.w(
      'Warning: Hung processes detected: '
      '${hungProcesses.join(", ")}',
    );
    logger.w(
      'Consider running "melos run clean" before a '
      'production build.',
    );
  } else {
    logger.i('No hung Dart/Flutter processes detected.');
  }

  // ── Chromebook early exit ────────────────────────────
  if (platform == 'CHROMEBOOK') {
    logger.i('--- Preflight Complete [CHROMEBOOK:STOP] ---');
    // ignore: avoid_print
    print('CHROMEBOOK:STOP');
    return;
  }

  // ── Step 4: Smart Skip Check ─────────────────────────
  logger.i('Step 4: Checking verification status...');
  final shouldRunMelos =
      forceRun || await _shouldRunMelos();
  if (forceRun) {
    logger.i('--force flag set — skipping smart-skip.');
  }

  if (shouldRunMelos) {
    logger.i('Verification stale or missing — running '
        'melos health suite...');

    // Format → Analyze → Test (sequential)
    final steps = [
      ['melos', 'run', 'format'],
      ['melos', 'run', 'analyze'],
      ['melos', 'run', 'test'],
    ];

    for (final step in steps) {
      final label = step.join(' ');
      logger.i('Running: $label');
      final result = await Process.run(
        step[0],
        step.sublist(1),
        runInShell: true,
      );

      // Stream output in real time through logger
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (stdout.isNotEmpty) logger.d(stdout);
      if (stderr.isNotEmpty) logger.e(stderr);

      if (result.exitCode != 0) {
        logger.e('FAIL: $label exited with ${result.exitCode}');
        exit(1);
      }
      logger.i('PASS: $label');
    }

    // Update verification_status.json
    await _updateVerificationStatus();
    logger.i('verification_status.json updated.');
  } else {
    logger.i(
      'Verification current — skipping melos suite.',
    );
  }

  logger.i('--- Preflight Complete [WINDOWS_10:VERIFIED] ---');
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
    final result = await Process.run('tasklist', []);
    final output = result.stdout.toString();
    if (output.contains('flutter.exe')) hung.add('flutter');
    if (output.contains('dart.exe')) hung.add('dart');
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
      logger.i(
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
      logger.i(
        'SHA match: $currentSha — skip eligible.',
      );
      return false;
    }

    logger.i(
      'SHA mismatch: HEAD=$currentSha vs '
      'verified=$lastSha — suite required.',
    );
    return true;
  } catch (e) {
    logger.w(
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
