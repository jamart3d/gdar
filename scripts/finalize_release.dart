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
  final date = DateTime.now().toIso8601String().split('T')[0];

  _info('--- Starting Release Housekeeping ($type) ---');

  // 1. Run bump_version.dart
  final bumpProcess = await Process.run('dart', [
    'scripts/bump_version.dart',
    type,
  ], runInShell: true);
  if (bumpProcess.exitCode != 0) {
    _err(
      'Error bumping version: '
      '${bumpProcess.stderr}',
    );
    exit(1);
  }

  // 2. Get the new version
  final versionProcess = await Process.run('dart', [
    'scripts/get_current_version.dart',
  ], runInShell: true);
  final newVersion = versionProcess.stdout.toString().trim();
  if (versionProcess.exitCode != 0 || newVersion.isEmpty) {
    _err(
      'Error: Version retrieval failed '
      '(exit ${versionProcess.exitCode}). '
      'Bump may have failed silently.',
    );
    exit(1);
  }
  _info('New Version: $newVersion');

  // 3. Read pending notes
  final pendingFile = File('.agent/notes/pending_release.md');
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
    final newBlock = '## [$newVersion] - $date\n\n$pendingContent\n\n';
    // Insert after ## [Unreleased]
    changelog = changelog.replaceFirst(
      '## [Unreleased]',
      '## [Unreleased]\n\n$newBlock',
    );
    changelogFile.writeAsStringSync(changelog);
    _info('Updated CHANGELOG.md');
  }

  // 5. Update docs/PLAY_STORE_RELEASE.txt
  final playStoreFile = File('docs/PLAY_STORE_RELEASE.txt');
  if (playStoreFile.existsSync()) {
    final oldPlayStore = playStoreFile.readAsStringSync();
    final userNotes = _distillPlayStoreNotes(pendingContent, newVersion);
    final newPlayEntry = '$userNotes\n\n---\n\n$oldPlayStore';
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

/// Distills raw pending_release.md content into a concise, user-facing
/// Play Store "What's New" block.
///
/// Rules applied (in order):
///   1. Section headers (`### Fixed`, `### Changed`, `### Tests`, etc.) are
///      dropped.
///   2. Continuation lines (indented / starts with `- File:`) are dropped.
///   3. Bullets tagged as test-only are dropped (those whose bold label starts
///      with `Test` case-insensitively, or section is `### Tests`).
///   4. Each retained bullet is trimmed to just the user-visible summary:
///      everything before the first ` — ` (em-dash), `Root cause:`, `Fix:`,
///      or `. File` is kept; the rest is discarded.
///   5. Markdown bold (`**…**`) is stripped so the text reads naturally.
///   6. The combined text is hard-capped at 500 chars (Play Store limit).
///   7. The block is wrapped in `<en-US>…</en-US>` XML tags.
String _distillPlayStoreNotes(String pendingContent, String newVersion) {
  final lines = pendingContent.split('\n');
  bool inTestsSection = false;
  final bullets = <String>[];

  for (final raw in lines) {
    final trimmed = raw.trim();

    // ── Section headers ──────────────────────────────────────────
    if (trimmed.startsWith('###')) {
      inTestsSection = trimmed.toLowerCase().contains('test');
      continue;
    }

    // ── Skip non-bullet lines (continuation / file paths / empty) ──
    if (!trimmed.startsWith('- ')) continue;

    // ── Skip bullets in the Tests section ────────────────────────
    if (inTestsSection) continue;

    // ── Skip bullets whose label is test-related ──────────────────
    final labelMatch = RegExp(r'^\-\s+\*\*([^*]+)\*\*').firstMatch(trimmed);
    if (labelMatch != null &&
        labelMatch.group(1)!.toLowerCase().startsWith('test')) {
      continue;
    }

    // ── Skip "- File:" continuation bullets ───────────────────────
    if (RegExp(r'^\-\s+Files?:', caseSensitive: false).hasMatch(trimmed)) {
      continue;
    }

    // ── Distill: keep only the user-facing summary ─────────────────
    // Strip bold markers first.
    var text = trimmed.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => m.group(1)!,
    );
    // Remove the leading "- ".
    text = text.replaceFirst(RegExp(r'^-\s+'), '');
    // Truncate at technical detail separators.
    for (final sep in [
      ' — ',
      ' – ',
      ' - Fix:',
      'Root cause:',
      '. File',
      '.\n',
    ]) {
      final idx = text.indexOf(sep);
      if (idx > 0) {
        text = text.substring(0, idx);
        break;
      }
    }
    // Remove trailing punctuation noise and trim.
    text = text.replaceAll(RegExp(r'[:\s]+$'), '').trim();
    if (text.isEmpty) continue;

    bullets.add('• $text');
  }

  if (bullets.isEmpty) {
    bullets.add('• Maintenance and stability improvements.');
  }

  // ── Compose header + bullets ──────────────────────────────────
  final header = "What's new in v$newVersion";
  var body = '$header\n${bullets.join('\n')}';

  // ── Enforce 500-char Play Store limit ─────────────────────────
  const limit = 500;
  if (body.length > limit) {
    // Drop bullets from the end until we fit.
    final mutableBullets = List<String>.from(bullets);
    while (mutableBullets.isNotEmpty) {
      body = '$header\n${mutableBullets.join('\n')}';
      if (body.length <= limit) break;
      mutableBullets.removeLast();
    }
    if (mutableBullets.isEmpty) {
      body = '$header\n• Maintenance and stability improvements.';
    }
  }

  // ── Wrap in Play Console locale tags ──────────────────────────
  return '<en-US>\n$body\n</en-US>';
}
