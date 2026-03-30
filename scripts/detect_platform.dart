import 'dart:io';

/// Unified platform detection for GDAR Zero-Friction workflows.
/// Returns 'WINDOWS_10' or 'CHROMEBOOK'.
void main() {
  if (Platform.isWindows) {
    stdout.write('WINDOWS_10');
  } else {
    // Default to CHROMEBOOK for the GDAR workflow context as per rules.
    stdout.write('CHROMEBOOK');
  }
}
