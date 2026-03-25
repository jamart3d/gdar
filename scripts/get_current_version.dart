import 'dart:io';

void main() {
  final file = File('apps/gdar_mobile/pubspec.yaml');
  if (!file.existsSync()) {
    exit(1);
  }

  final content = file.readAsStringSync();
  final versionMatch = RegExp(
    r'^version: (.+)$',
    multiLine: true,
  ).firstMatch(content);

  if (versionMatch != null) {
    // ignore: avoid_print
    print(versionMatch.group(1));
  } else {
    exit(1);
  }
}
