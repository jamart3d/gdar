import 'dart:io';

// ── Zero-dependency ANSI logger ─────────────────────────
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _red = '\x1B[31m';
const _dim = '\x1B[2m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('ℹ️', _green, msg);
void _err(String msg) => _log('❌', _red, msg);
void _debug(String msg) => _log('  ', _dim, msg);

/// Unified Save & Sync script for GDAR.
/// Performs git add/commit/push and prunes empty notes.
void main(List<String> args) async {
  final message = args.isNotEmpty
      ? args.join(' ')
      : '[Auto-Save] Workspace synchronization';

  _info('--- Starting Atomic Save ---');

  // 1. Git Sequence
  _info('Step 1: Git Sync...');
  await _run('git', ['add', '.']);
  final commitRes =
      await _run('git', ['commit', '-m', message]);
  if (commitRes.exitCode == 0) {
    await _run('git', ['push']);
  } else {
    _err('No changes to commit or commit failed.');
  }

  // 2. Prune Notes
  _info('Step 2: Pruning empty notes...');
  final notesDir = Directory('.agent/notes');
  if (notesDir.existsSync()) {
    for (final file
        in notesDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.md')) {
        final content = file.readAsStringSync().trim();
        // Check if it's effectively empty (header only)
        if (content.isEmpty ||
            (content.split('\n').length <= 2 &&
                content.startsWith('#'))) {
          _info('Deleting empty note: ${file.path}');
          file.deleteSync();
        }
      }
    }
  }

  _info('--- Save & Sync Complete ---');
}

Future<ProcessResult> _run(
  String cmd,
  List<String> args,
) async {
  final res = await Process.run(cmd, args);
  if (res.stdout.toString().isNotEmpty) {
    _debug(res.stdout.toString());
  }
  if (res.stderr.toString().isNotEmpty) {
    _err(res.stderr.toString());
  }
  return res;
}
