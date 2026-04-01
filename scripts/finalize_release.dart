import 'dart:io';

// ── Zero-dependency ANSI logger ─────────────────────────
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _red = '\x1B[31m';

void _log(String icon, String color, String msg) =>
    stdout.writeln('$color$icon $msg$_reset');
void _info(String msg) => _log('ℹ️', _green, msg);
void _err(String msg) => _log('❌', _red, msg);

/// Finalizes the release housekeeping for GDAR.
/// 1. Bumps the version (patch/minor).
/// 2. Migrates notes from pending_release.md to CHANGELOG.md.
/// 3. Prepends notes to PLAY_STORE_RELEASE.txt.
/// 4. Clears pending_release.md.
void main(List<String> args) async {
  final type = args.isNotEmpty ? args[0] : 'patch';
  final date =
      DateTime.now().toIso8601String().split('T')[0];

  _info('--- Starting Release Housekeeping ($type) ---');

  // 1. Run bump_version.dart
  final bumpProcess = await Process.run(
    'dart',
    ['scripts/bump_version.dart', type],
    runInShell: true,
  );
  if (bumpProcess.exitCode != 0) {
    _err(
      'Error bumping version: '
      '${bumpProcess.stderr}',
    );
    exit(1);
  }

  // 2. Get the new version
  final versionProcess = await Process.run(
    'dart',
    ['scripts/get_current_version.dart'],
    runInShell: true,
  );
  final newVersion =
      versionProcess.stdout.toString().trim();
  if (versionProcess.exitCode != 0 ||
      newVersion.isEmpty) {
    _err(
      'Error: Version retrieval failed '
      '(exit ${versionProcess.exitCode}). '
      'Bump may have failed silently.',
    );
    exit(1);
  }
  _info('New Version: $newVersion');

  // 3. Read pending notes
  final pendingFile =
      File('.agent/notes/pending_release.md');
  String pendingContent = '';
  if (pendingFile.existsSync()) {
    final lines = pendingFile.readAsLinesSync();
    final notes = <String>[];
    bool inUnreleased = false;
    for (final line in lines) {
      if (line.contains('## [Unreleased]')) {
        inUnreleased = true;
        continue;
      }
      if (inUnreleased && line.trim().isNotEmpty) {
        notes.add(line);
      }
    }
    pendingContent = notes.join('\n');
  }

  if (pendingContent.isEmpty) {
    pendingContent =
        '- **Maintenance**: General maintenance '
        'and version synchronization.';
  }

  // 4. Update CHANGELOG.md
  final changelogFile = File('CHANGELOG.md');
  if (changelogFile.existsSync()) {
    String changelog = changelogFile.readAsStringSync();
    final newBlock =
        '## [$newVersion] - $date\n\n$pendingContent\n\n';
    // Insert after ## [Unreleased]
    changelog = changelog.replaceFirst(
      '## [Unreleased]',
      '## [Unreleased]\n\n$newBlock',
    );
    changelogFile.writeAsStringSync(changelog);
    _info('Updated CHANGELOG.md');
  }

  // 5. Update docs/PLAY_STORE_RELEASE.txt
  final playStoreFile =
      File('docs/PLAY_STORE_RELEASE.txt');
  if (playStoreFile.existsSync()) {
    final oldPlayStore =
        playStoreFile.readAsStringSync();
    // Simple format for Play Store (keep bullets)
    final lines = pendingContent
        .split('\n')
        .where((l) => l.trim().startsWith('-'))
        .join('\n');
    final newPlayEntry = "What's new in v$newVersion\n"
        '$lines\n\n---\n\n$oldPlayStore';
    playStoreFile.writeAsStringSync(newPlayEntry);
    _info('Updated docs/PLAY_STORE_RELEASE.txt');
  }

  // 6. Reset pending_release.md
  pendingFile.writeAsStringSync(
    '# Pending Release Notes\n'
    '[Unreleased] entries will be moved to '
    'CHANGELOG.md during the next /shipit run.\n\n'
    '## [Unreleased]\n',
  );
  _info('Reset pending_release.md');

  _info('--- Housekeeping Complete ---');
}
