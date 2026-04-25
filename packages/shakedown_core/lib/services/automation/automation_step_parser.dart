import 'package:shakedown_core/services/automation/automation_step.dart';

List<AutomationStep> parseAutomationSteps(List<String> rawSteps) {
  final parsed = <AutomationStep>[];

  for (final raw in rawSteps) {
    final step = raw.trim();
    if (step == 'dice') {
      parsed.add(const AutomationStep.playRandomShow());
      continue;
    }
    if (step == 'screensaver') {
      parsed.add(const AutomationStep.launchScreensaver());
      continue;
    }
    if (step.startsWith('sleep:')) {
      final seconds = int.tryParse(step.split(':')[1]);
      if (seconds != null) {
        parsed.add(AutomationStep.sleep(seconds: seconds));
      }
      continue;
    }
    if (step.startsWith('settings:')) {
      final payload = step.substring('settings:'.length);
      final keyValue = payload.split('=');
      if (keyValue.length == 2) {
        parsed.add(
          AutomationStep.setSetting(key: keyValue[0], value: keyValue[1]),
        );
      }
    }
  }

  return parsed;
}
