import 'dart:io';
import 'package:logger/logger.dart';

// Configure a beautiful, colorful logger for the micro-scanner output.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // No method stack trace for normal info
    errorMethodCount: 5, // Include trace on errors if available
    lineLength: 80,
    colors: true, // Enable colorful output in terminal
    printEmojis: true, // Print an emoji for each log level
    dateTimeFormat: DateTimeFormat.none, // Keep it clean for short scripts
  ),
);

Future<void> main() async {
  // Collect modified/added files (staged or unstaged)
  final result = await Process.run('git', ['diff', '--name-only', 'HEAD']);

  if (result.exitCode != 0) {
    logger.e('Git command failed: ${result.stderr}');
    exit(1);
  }

  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    logger.i('No changed files found. Micro-scanner skipping.');
    exit(0);
  }

  // Filter for only .dart files
  final changedFiles = output
      .split('\n')
      .map((line) => line.trim())
      .where((file) => file.endsWith('.dart'))
      .toList();

  if (changedFiles.isEmpty) {
    logger.i('No changed Dart files found. Micro-scanner skipping.');
    exit(0);
  }

  logger.i(
    'Scanning ${changedFiles.length} pending file(s) for styling constraints...',
  );

  int violations = 0;

  for (final filePath in changedFiles) {
    final file = File(filePath);

    // Skip if file was deleted
    if (!await file.exists()) {
      continue;
    }

    final lines = await file.readAsLines();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Target 1: withOpacity() - Modern syntax requirement
      if (line.contains('withOpacity(')) {
        logger.w(
          'Legacy \'withOpacity()\' found in $filePath:${i + 1}\n'
          '   -> Please use the modern \'.withValues()\' method.',
        );
        violations++;
      }

      // Target 2: Colors.* - Breaks multi-platform guidelines
      if (line.contains('Colors.')) {
        logger.w(
          'Hardcoded \'Colors.\' found in $filePath:${i + 1}\n'
          '   -> Please use semantic theme variables or styles to support Dark Mode / Fruit.',
        );
        violations++;
      }
    }
  }

  if (violations > 0) {
    logger.e(
      'Micro-Scanner failed! Found $violations violation(s).\n'
      '   Please fix the listed items to pass the checkup workflow.',
    );
    exit(1);
  }

  logger.i(
    'Micro-Scanner passed. No styling violations found in pending files.',
  );
  exit(0);
}
