import 'dart:io';
import 'dart:convert';
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

/// Unified Save & Sync script for GDAR.
/// Performs git add/commit/push, prunes empty notes, and updates status receipts.
void main(List<String> args) async {
  final message = args.isNotEmpty ? args.join(' ') : '[Auto-Save] Workspace synchronization';

  logger.i('--- Starting Atomic Save ---');

  // 1. Git Sequence
  logger.i('Step 1: Git Sync...');
  await _run('git', ['add', '.']);
  final commitRes = await _run('git', ['commit', '-m', message]);
  if (commitRes.exitCode == 0) {
    await _run('git', ['push']);
  } else {
    logger.e('No changes to commit or commit failed.');
  }

  // 2. Prune Notes
  logger.i('Step 2: Pruning empty notes...');
  final notesDir = Directory('.agent/notes');
  if (notesDir.existsSync()) {
    for (final file in notesDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.md')) {
        final content = file.readAsStringSync().trim();
        // Check if it's effectively empty (header only)
        if (content.isEmpty || (content.split('\n').length <= 2 && content.startsWith('#'))) {
          logger.i('Deleting empty note: ${file.path}');
          file.deleteSync();
        }
      }
    }
  }

  // 3. Update Verification Receipt (Smart Receipt)
  logger.i('Step 3: Updating verification receipt...');
  final shaProcess = await Process.run('git', ['rev-parse', 'HEAD']);
  final sha = shaProcess.stdout.toString().trim();

  final statusFile = File('.agent/notes/verification_status.json');
  if (statusFile.existsSync()) {
    final Map<String, dynamic> data = jsonDecode(statusFile.readAsStringSync());
    data['last_verification_commit'] = sha;
    data['status'] = 'saved';
    data['timestamp'] = DateTime.now().toIso8601String();
    statusFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    logger.i('Updated verification_status.json to SHA: $sha');
  }

  logger.i('--- Save & Sync Complete ---');
}

Future<ProcessResult> _run(String cmd, List<String> args) async {
  final res = await Process.run(cmd, args);
  if (res.stdout.toString().isNotEmpty) logger.d(res.stdout);
  if (res.stderr.toString().isNotEmpty) logger.e(res.stderr);
  return res;
}
