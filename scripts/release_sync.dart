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

/// Unified Release Sync script for GDAR.
/// Performs final git add, commit, tag, and push.
void main(List<String> args) async {
  logger.i('--- Starting Final Release Sync ---');

  // 1. Get Version
  final versionProcess = await Process.run('dart', ['scripts/get_current_version.dart']);
  final version = versionProcess.stdout.toString().trim();
  if (version.isEmpty) {
    logger.e('Error: Could not retrieve current version.');
    exit(1);
  }
  final tag = 'v$version';
  final message = 'release: $version';

  // 2. Git Sequence
  logger.i('Step 1: Staging changes...');
  await _run('git', ['add', '.']);

  logger.i('Step 2: Committing release...');
  final commitRes = await _run('git', ['commit', '-m', message]);
  if (commitRes.exitCode != 0) {
    logger.e('Commit failed - worktree might be clean or error occurred.');
    // Don't exit if no changes, but usually shipit has changes (version bump)
  }

  logger.i('Step 3: Tagging release ($tag)...');
  await _run('git', ['tag', tag]);

  logger.i('Step 4: Pushing to main...');
  await _run('git', ['push', 'origin', 'main']);

  logger.i('Step 5: Pushing tags...');
  await _run('git', ['push', '--tags']);

  logger.i('--- Release Sync Complete ---');
}

Future<ProcessResult> _run(String cmd, List<String> args) async {
  final res = await Process.run(cmd, args);
  if (res.stdout.toString().isNotEmpty) logger.d(res.stdout);
  if (res.stderr.toString().isNotEmpty) logger.e(res.stderr);
  return res;
}
