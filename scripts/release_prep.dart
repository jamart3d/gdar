// ignore_for_file: avoid_print
import 'dart:io';

/// Prepares the GDAR monorepo for release by migrating [Unreleased] changelog
/// entries and updating the Play Store release notes.
///
/// Usage:
///   dart scripts/release_prep.dart [version]
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart scripts/release_prep.dart <version>');
    exit(1);
  }

  final String version = args[0];
  final String date = DateTime.now().toIso8601String().split('T')[0];

  final changelogFile = File('CHANGELOG.md');
  final playStoreFile = File('docs/PLAY_STORE_RELEASE.txt');

  if (!changelogFile.existsSync()) {
    print('Error: CHANGELOG.md not found.');
    exit(1);
  }

  String changelog = changelogFile.readAsStringSync();

  // 1. Find the [Unreleased] section
  final unreleasedRegex = RegExp(
    r'## \[Unreleased\]\n(.*?)(?=\n## \[|$)',
    dotAll: true,
  );
  final match = unreleasedRegex.firstMatch(changelog);

  if (match == null || match.group(1)!.trim().isEmpty) {
    print('Error: No [Unreleased] changes found in CHANGELOG.md.');
    exit(1);
  }

  final String changes = match.group(1)!.trim();
  final String newHeader = '## [$version] - $date';
  final String newBlock = '$newHeader\n\n$changes\n';

  // 2. Replace [Unreleased] with the new versioned block and add a fresh [Unreleased]
  final updatedChangelog = changelog.replaceFirst(
    unreleasedRegex,
    '## [Unreleased]\n\n$newBlock',
  );
  changelogFile.writeAsStringSync(updatedChangelog);

  // 3. Update docs/PLAY_STORE_RELEASE.txt
  if (playStoreFile.existsSync()) {
    final String oldPlayStore = playStoreFile.readAsStringSync();
    final String playStoreEntries = _convertToPlayStoreFormat(changes);
    final String newPlayStore =
        'What\'s new in v$version\n$playStoreEntries\n\n---\n\n$oldPlayStore';
    playStoreFile.writeAsStringSync(newPlayStore);
  }

  print('Successfully prepared release for version $version.');
}

String _convertToPlayStoreFormat(String changelogChanges) {
  // Simple conversion: keep list items, remove category headers (### Added, etc.)
  final lines = changelogChanges.split('\n');
  final result = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- ')) {
      result.add(trimmed);
    }
  }

  return result.join('\n');
}
