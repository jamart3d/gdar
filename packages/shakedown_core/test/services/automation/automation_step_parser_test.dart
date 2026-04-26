import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/automation/automation_step.dart';
import 'package:shakedown_core/services/automation/automation_step_parser.dart';

void main() {
  test('parseSteps converts supported step strings into typed steps', () {
    final steps = parseAutomationSteps(<String>[
      'dice',
      'sleep:3',
      'settings:force_tv=true',
      'screensaver',
    ]);

    expect(steps, <AutomationStep>[
      const AutomationStep.playRandomShow(),
      const AutomationStep.sleep(seconds: 3),
      const AutomationStep.setSetting(key: 'force_tv', value: 'true'),
      const AutomationStep.launchScreensaver(),
    ]);
  });
}
