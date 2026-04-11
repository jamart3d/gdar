import 'dart:io';

// ── Zero-dependency ANSI logger ─────────────────────────
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';
const _dim = '\x1B[2m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('ℹ️', _green, msg);
void _warn(String msg) => _log('⚠️', _yellow, msg);
void _err(String msg) => _log('❌', _red, msg);
void _debug(String msg) => _log('  ', _dim, msg);

/// Unified Release Sync script for GDAR.
/// Performs final git add, commit, tag, and push.
void main(List<String> args) async {
  _info('--- Starting Final Release Sync ---');

  // 1. Get Version
  final versionProcess = await Process.run('dart', [
    'scripts/get_current_version.dart',
  ], runInShell: true);
  final version = versionProcess.stdout.toString().trim();
  if (versionProcess.exitCode != 0 || version.isEmpty) {
    _err(
      'Error: Could not retrieve current version '
      '(exit ${versionProcess.exitCode}).',
    );
    exit(1);
  }
  final tag = 'v$version';
  final message = 'release: $version';

  // 2. Git Sequence
  _info('Step 1: Staging changes...');
  await _run('git', ['add', '.']);

  _info('Step 2: Committing release...');
  final commitRes = await _run('git', ['commit', '-m', message]);
  if (commitRes.exitCode != 0) {
    _warn(
      'Commit returned ${commitRes.exitCode} — '
      'worktree might be clean.',
    );
  }

  _info('Step 3: Tagging release ($tag)...');
  final tagRes = await _run('git', ['tag', tag]);
  if (tagRes.exitCode != 0) {
    _err(
      'FAIL: git tag "$tag" failed '
      '(exit ${tagRes.exitCode}). '
      'Tag may already exist.',
    );
    exit(1);
  }

  _info('Step 4: Pushing to main...');
  await _run('git', ['push', 'origin', 'main']);

  _info('Step 5: Pushing tags...');
  await _run('git', ['push', '--tags']);

  _info('--- Release Sync Complete ---');
}

Future<ProcessResult> _run(String cmd, List<String> args) async {
  final res = await Process.run(cmd, args, runInShell: true);
  if (res.stdout.toString().isNotEmpty) {
    _debug(res.stdout.toString());
  }
  if (res.stderr.toString().isNotEmpty) {
    _err(res.stderr.toString());
  }
  return res;
}
