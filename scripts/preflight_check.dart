// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'preflight_support.dart';
import 'verification_status_support.dart';

const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';
const _cyan = '\x1B[36m';
const _dim = '\x1B[2m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('info', _green, msg);
void _step(String msg) => _log('step', _cyan, msg);
void _warn(String msg) => _log('warn', _yellow, msg);
void _err(String msg) => _log('fail', _red, msg);
void _debug(String msg) => _log('  ', _dim, msg);

/// Unified Preflight & Verification script for GDAR.
///
/// Handles the entire pre-build pipeline in one shot:
/// 1. Detects host platform (WINDOWS_10, LINUX, or CHROMEBOOK).
/// 2. Verifies toolchain (git, dart, flutter, firebase).
/// 3. Checks for hung processes.
/// 4. Smart-skip: compares verification_status.json SHA against current HEAD.
/// 5. Updates verification_status.json on success unless `--preflight-only`
///    was requested for `/checkup`.
///
/// Exit codes:
///   0 = success (stdout ends with WINDOWS_10:VERIFIED,
///       LINUX:VERIFIED, or CHROMEBOOK:STOP)
///   1 = toolchain missing or melos suite failed
void main(List<String> args) async {
  final options = parsePreflightOptions(args);

  _info('--- Starting GDAR Preflight ---');

  if (options.recordStatusOnly) {
    _step('Step 1: Refreshing verification receipt...');
    await _updateVerificationStatus();
    _info('verification_status.json updated.');
    _info('--- Preflight Complete [RECORD_PASS:VERIFIED] ---');
    print('RECORD_PASS:VERIFIED');
    return;
  }

  _step('Step 1: Detecting Host Class...');
  final platform = _detectPlatform();
  _info('Host: $platform');

  _step('Step 2: Checking Toolchain...');
  final commands = ['git', 'dart', 'flutter'];
  if (options.isRelease) {
    commands.add('firebase');
  }

  for (final command in commands) {
    if (!await _commandExists(command)) {
      _err('FAIL: Command "$command" not found in PATH.');
      exit(1);
    }
  }
  _info('Toolchain verified: ${commands.join(", ")}');

  _step('Step 3: Checking Process Hygiene...');
  final hungProcesses = await _findHungProcesses();
  if (hungProcesses.isNotEmpty) {
    _warn('Warning: Hung processes detected: ${hungProcesses.join(", ")}');
    _warn('Consider running "melos run clean" before a production build.');
  } else {
    _info('No hung Dart/Flutter processes detected.');
  }

  if (platform == 'CHROMEBOOK') {
    _info('--- Preflight Complete [CHROMEBOOK:STOP] ---');
    print('CHROMEBOOK:STOP');
    return;
  }

  _step('Step 4: Checking verification status...');
  if (!options.runMelos) {
    _info('Preflight-only mode: skipping melos suite and receipt write.');
  } else {
    final shouldRunMelos = options.forceRun || await _shouldRunMelos();
    if (options.forceRun) {
      _info('--force flag set: skipping smart-skip.');
    }

    if (shouldRunMelos) {
      _info('Verification stale or missing: running melos health suite...');

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

      if (options.writeStatus) {
        await _updateVerificationStatus();
        _info('verification_status.json updated.');
      }
    } else {
      _info('Verification current: skipping melos suite.');
    }
  }

  _info('--- Preflight Complete [$platform:VERIFIED] ---');
  print('$platform:VERIFIED');
}

String _detectPlatform() {
  if (Platform.isWindows) {
    return 'WINDOWS_10';
  }
  if (Platform.isLinux) {
    return 'LINUX';
  }
  return 'CHROMEBOOK';
}

Future<bool> _commandExists(String command) async {
  final checkCommand = Platform.isWindows ? 'where' : 'which';
  final result = await Process.run(checkCommand, [command]);
  return result.exitCode == 0;
}

Future<List<String>> _findHungProcesses() async {
  if (Platform.isWindows) {
    final result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
    return detectWindowsToolProcesses(result.stdout.toString(), selfPid: pid);
  }

  return <String>[];
}

Future<bool> _shouldRunMelos() async {
  final statusFile = File('.agent/notes/verification_status.json');
  if (!statusFile.existsSync()) {
    return true;
  }

  try {
    final data =
        jsonDecode(statusFile.readAsStringSync()) as Map<String, dynamic>;
    final lastSha = data['last_verification_commit'] as String? ?? '';
    final status = data['status'] as String? ?? '';

    if (status != 'PASS') {
      _info('Status is "$status" (not PASS): suite required.');
      return true;
    }

    final headResult = await Process.run('git', ['rev-parse', 'HEAD']);
    final currentSha = headResult.stdout.toString().trim();

    if (lastSha == currentSha) {
      _info('SHA match: $currentSha : skip eligible.');
      return false;
    }

    _info(
      'SHA mismatch: HEAD=$currentSha vs verified=$lastSha : suite required.',
    );
    return true;
  } catch (error) {
    _warn('Could not parse verification_status.json: $error');
    return true;
  }
}

Future<void> _updateVerificationStatus() async {
  final headResult = await Process.run('git', ['rev-parse', 'HEAD']);
  final sha = headResult.stdout.toString().trim();

  final data = buildPassVerificationStatus(sha: sha, timestamp: DateTime.now());

  final file = File('.agent/notes/verification_status.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}
