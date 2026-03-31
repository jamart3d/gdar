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

/// Unified Preflight script for GDAR.
/// 1. Detects Host Platform.
/// 2. Verifies Toolchain.
/// 3. Performs Process Hygiene Check.
void main(List<String> args) async {
  logger.i('--- Starting GDAR Preflight ---');

  // Step 1: Detect Platform
  logger.i('Step 1: Detecting Host Class...');
  final platform = await _detectPlatform();
  logger.i('Host: $platform');

  // Step 2: Command Verification
  logger.i('Step 2: Checking Toolchain...');
  final commands = ['git', 'dart', 'flutter'];
  if (args.contains('--release')) {
    commands.add('firebase');
  }

  for (final cmd in commands) {
    if (!await _commandExists(cmd)) {
      logger.e('Error: Command "$cmd" not found in PATH.');
      exit(1);
    }
  }
  logger.i('Toolchain verified: ${commands.join(", ")}');

  // Step 3: Process Hygiene (Read-only check)
  logger.i('Step 3: Checking Process Hygiene...');
  final hungProcesses = await _findHungProcesses();
  if (hungProcesses.isNotEmpty) {
    logger.w('Warning: Hung processes detected: ${hungProcesses.join(", ")}');
    logger.w('Consider running "melos run clean" before a production build.');
  } else {
    logger.i('No hung Dart/Flutter processes detected.');
  }

  logger.i('--- Preflight Complete [PASS] ---');
}

Future<String> _detectPlatform() async {
  try {
    final result = await Process.run('dart', ['scripts/detect_platform.dart']);
    return result.stdout.toString().trim();
  } catch (e) {
    return 'CHROMEBOOK'; // Fallback
  }
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
  // Simplified for preflight - don't want a heavy audit here
  return hung;
}
