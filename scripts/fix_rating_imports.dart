// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final files = [
    r'c:\Users\jeff\StudioProjects\gdar\apps\gdar_web\lib\ui\widgets\source_list_item.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\test\ui\widgets\rating_control_fruit_color_test.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\test\screens\playback_screen_test.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\show_list\show_list_card_fruit_car_mode.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\show_list\show_list_card_fruit_mobile.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\show_list\show_list_card_controls.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\source_list_item.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\playback\playback_app_bar.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\widgets\playback\playback_panel.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\playback_screen_fruit_car_mode.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\rated_shows_screen.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\track_list_screen_fruit.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\tv_playback_screen_build.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\track_list_screen_build.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\playback_screen_fruit_build.dart',
    r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\lib\ui\screens\show_list\show_list_logic_mixin.dart',
  ];

  const importString =
      "import 'package:shakedown_core/ui/widgets/rating_dialog.dart';\n";
  final Set<String> patched = {};

  for (var path in files) {
    if (!File(path).existsSync()) continue;
    var content = File(path).readAsStringSync();

    // Check if it's a part file
    final partMatch = RegExp(r"part of\s+'([^']+)';").firstMatch(content);
    if (partMatch != null) {
      final parentFile = partMatch.group(1)!;
      final uri = Uri.file(path).resolve(parentFile);
      path = uri.toFilePath();
      content = File(path).readAsStringSync();
    }

    if (!patched.contains(path) && !content.contains(importString)) {
      // Find the last import statment
      final lastImportIndex = content.lastIndexOf(
        RegExp(r'^import\s+.*?;', multiLine: true),
      );
      if (lastImportIndex != -1) {
        final insertionPoint = content.indexOf(';', lastImportIndex) + 1;
        content =
            '${content.substring(0, insertionPoint)}\n$importString${content.substring(insertionPoint)}';
        File(path).writeAsStringSync(content);
        patched.add(path);
        print('Patched $path');
      }
    }
  }
}
