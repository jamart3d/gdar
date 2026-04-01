import 'dart:io';

/// Cross-platform version bumper for the GDAR monorepo.
///
/// Usage:
///   dart scripts/bump_version.dart x.y.z+build
///   dart scripts/bump_version.dart patch  # increments patch and build (+1)
///   dart scripts/bump_version.dart minor  # increments minor and build (+1)
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Error: No version argument provided.\n'
      'Usage: dart scripts/bump_version.dart '
      '<patch|minor|major|x.y.z+build>',
    );
    exit(1);
  }

  final String input = args[0];
  final appTargets = [
    'apps/gdar_mobile/pubspec.yaml',
    'apps/gdar_tv/pubspec.yaml',
    'apps/gdar_web/pubspec.yaml',
  ];

  // 1. Get current version from mobile (canonical source)
  final mobilePubspec = File(appTargets[0]);
  if (!mobilePubspec.existsSync()) {
    stderr.writeln(
      'Error: ${appTargets[0]} not found. '
      'Are you running from the repo root?',
    );
    exit(1);
  }

  final content = mobilePubspec.readAsStringSync();
  final versionMatch = RegExp(
    r'^version: (.+)$',
    multiLine: true,
  ).firstMatch(content);
  if (versionMatch == null) {
    stderr.writeln(
      'Error: No "version:" line found in '
      '${appTargets[0]}.',
    );
    exit(1);
  }

  final String currentVersion = versionMatch.group(1)!;
  String nextVersion;

  if (input == 'patch' || input == 'minor' || input == 'major') {
    nextVersion = _calculateNext(currentVersion, input);
  } else {
    nextVersion = input;
  }

  // 2. Update all targets
  for (final path in appTargets) {
    final file = File(path);
    if (file.existsSync()) {
      final oldContent = file.readAsStringSync();
      final newContent = oldContent.replaceFirst(
        RegExp(r'^version: .+$', multiLine: true),
        'version: $nextVersion',
      );
      file.writeAsStringSync(newContent);
    }
  }

  // ignore: avoid_print
  print('$currentVersion → $nextVersion');
}

String _calculateNext(String current, String type) {
  // Pattern: major.minor.patch+build
  final match = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$',
  ).firstMatch(current);
  if (match == null) {
    stderr.writeln(
      'Error: Could not parse version "$current". '
      'Expected format: major.minor.patch+build',
    );
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  build++; // Always bump build

  if (type == 'patch') {
    patch++;
  } else if (type == 'minor') {
    minor++;
    patch = 0;
  } else if (type == 'major') {
    major++;
    minor = 0;
    patch = 0;
  }

  return '$major.$minor.$patch+$build';
}
