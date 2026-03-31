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

/// Finalizes the release housekeeping for GDAR.
/// 1. Bumps the version (patch/minor).
/// 2. Migrates notes from pending_release.md to CHANGELOG.md.
/// 3. Prepends notes to PLAY_STORE_RELEASE.txt.
/// 4. Clears pending_release.md.
void main(List<String> args) async {
  final type = args.isNotEmpty ? args[0] : 'patch';
  final date = DateTime.now().toIso8601String().split('T')[0];

  logger.i('--- Starting Release Housekeeping ($type) ---');

  // 1. Run bump_version.dart
  final bumpProcess = await Process.run(
    'dart',
    ['scripts/bump_version.dart', type],
  );
  if (bumpProcess.exitCode != 0) {
    logger.e('Error bumping version: ${bumpProcess.stderr}');
    exit(1);
  }

  // 2. Get the new version
  final versionProcess = await Process.run(
    'dart',
    ['scripts/get_current_version.dart'],
  );
  final newVersion = versionProcess.stdout.toString().trim();
  logger.i('New Version: $newVersion');

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
        notes.add(line.trim());
      }
    }
    pendingContent = notes.join('\n');
  }

  if (pendingContent.isEmpty) {
    pendingContent = '- **Maintenance**: General maintenance and version synchronization.';
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
    logger.i('Updated CHANGELOG.md');
  }

  // 5. Update docs/PLAY_STORE_RELEASE.txt
  final playStoreFile = File('docs/PLAY_STORE_RELEASE.txt');
  if (playStoreFile.existsSync()) {
    final oldPlayStore = playStoreFile.readAsStringSync();
    // Simple format for Play Store (keep bullets)
    final lines = pendingContent.split('\n')
        .where((l) => l.trim().startsWith('-'))
        .join('\n');
    final newPlayEntry = "What's new in v$newVersion\n$lines\n\n---\n\n$oldPlayStore";
    playStoreFile.writeAsStringSync(newPlayEntry);
    logger.i('Updated docs/PLAY_STORE_RELEASE.txt');
  }

  // 6. Reset pending_release.md
  pendingFile.writeAsStringSync(
    '# Pending Release Notes\n[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.\n\n## [Unreleased]\n',
  );
  logger.i('Reset pending_release.md');

  logger.i('--- Housekeeping Complete ---');
}
