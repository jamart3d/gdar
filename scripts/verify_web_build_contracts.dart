import 'dart:io';

const Map<String, String> requiredEngineContracts = <String, String>{
  'gapless_audio_engine.js': 'onPlayBlocked: function (cb)',
  'html5_audio_engine.js': 'onPlayBlocked: function (cb)',
  'hybrid_audio_engine.js': 'onPlayBlocked: function (cb)',
  'passive_audio_engine.js': 'onPlayBlocked: function (cb)',
};

List<String> findWebBuildContractIssues(String buildWebDir) {
  final issues = <String>[];

  for (final entry in requiredEngineContracts.entries) {
    final file = File(_join(buildWebDir, entry.key));
    if (!file.existsSync()) {
      issues.add('Missing built engine asset: ${entry.key}');
      continue;
    }

    final content = file.readAsStringSync();
    if (!content.contains(entry.value)) {
      issues.add('Missing required contract "${entry.value}" in ${entry.key}');
    }
  }

  return issues;
}

Future<void> main(List<String> args) async {
  final buildWebDir = args.isEmpty ? _join('build', 'web') : args.first;
  final issues = findWebBuildContractIssues(buildWebDir);

  if (issues.isEmpty) {
    stdout.writeln('Verified web build contracts in $buildWebDir.');
    return;
  }

  stderr.writeln('Web build contract verification failed for $buildWebDir:');
  for (final issue in issues) {
    stderr.writeln('- $issue');
  }
  exitCode = 1;
}

String _join(String left, String right) {
  final separator = Platform.pathSeparator;
  if (left.endsWith(separator)) {
    return '$left$right';
  }
  return '$left$separator$right';
}
