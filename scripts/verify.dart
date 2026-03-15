import 'dart:io';

Future<void> main(List<String> args) async {
  var runFormat = true;
  var runAnalyze = true;

  final targets = <String>[];

  for (final arg in args) {
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        return;
      case '--no-format':
        runFormat = false;
        break;
      case '--no-analyze':
        runAnalyze = false;
        break;
      default:
        targets.add(arg);
        break;
    }
  }

  if (!runFormat && !runAnalyze) {
    stderr.writeln('Nothing to run: both format and analyze are disabled.');
    exitCode = 2;
    return;
  }

  final effectiveTargets = targets.isEmpty
      ? <String>['apps', 'packages', 'scripts']
      : targets;

  for (final target in effectiveTargets) {
    final type = FileSystemEntity.typeSync(target);
    if (type == FileSystemEntityType.notFound) {
      stderr.writeln('Target not found: $target');
      exitCode = 2;
      return;
    }
  }

  if (runFormat) {
    final formatExit = await _runCommand(
      executable: 'dart',
      arguments: ['format', ...effectiveTargets],
      label: 'Formatting',
    );
    if (formatExit != 0) {
      exitCode = formatExit;
      return;
    }
  }

  if (runAnalyze) {
    final analyzeExit = await _runCommand(
      executable: 'dart',
      arguments: ['analyze', ...effectiveTargets],
      label: 'Analyzing',
    );
    if (analyzeExit != 0) {
      exitCode = analyzeExit;
      return;
    }
  }

  stdout.writeln('Verify complete.');
}

Future<int> _runCommand({
  required String executable,
  required List<String> arguments,
  required String label,
}) async {
  stdout.writeln('\n$label: $executable ${arguments.join(' ')}');

  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );

  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('$label failed with exit code $code.');
  }
  return code;
}

void _printUsage() {
  stdout.writeln('Usage:');
  stdout.writeln('  dart run scripts/verify.dart [options] [targets...]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --no-format   Skip formatting check');
  stdout.writeln('  --no-analyze  Skip static analysis check');
  stdout.writeln('  -v, --verbose Show detailed output');
  stdout.writeln('  -h, --help    Show this help message');
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run scripts/verify.dart');
  stdout.writeln('  dart run scripts/verify.dart apps packages');
  stdout.writeln('  dart run scripts/verify.dart --no-format apps');
}
