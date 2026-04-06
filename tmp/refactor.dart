import 'dart:io';

void main() {
  final file = File(
    'packages/shakedown_core/lib/ui/widgets/settings/appearance_section_controls.dart',
  );
  file.readAsStringSync();

  // We'll write to new files for each domain

  // But wait, it's safer to just split it by reading it.
}
