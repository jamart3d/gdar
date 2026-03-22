import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'env_detect_stub.dart' if (dart.library.io) 'env_detect_io.dart';

// Create a single, globally accessible logger instance.
final logger = Logger(
  // The printer can be customized for different looks.
  // PrettyPrinter is great for development as it's colorful and structured.
  // Use SimplePrinter during tests to avoid overlapping ASCII boxes in concurrent test runs.
  printer: isTestEnvironment
      ? SimplePrinter(colors: false)
      : PrettyPrinter(
          methodCount: 1, // Number of method calls to be displayed
          errorMethodCount:
              8, // Number of method calls if stacktrace is provided
          lineLength: 120, // Width of the log print
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          dateTimeFormat:
              DateTimeFormat.none, // Should each log print contain a timestamp
        ),
);

/// Initializes the logger with a level appropriate for the current build mode.
/// - In debug mode, all logs are shown.
/// - In profile mode, only info, warnings, and errors are shown.
/// - In release mode, only warnings and errors are shown.
void initLogger() {
  if (kReleaseMode) {
    Logger.level = Level.warning;
  } else if (kProfileMode) {
    Logger.level = Level.info;
  } else {
    // kDebugMode
    Logger.level = Level.trace;
  }
}
