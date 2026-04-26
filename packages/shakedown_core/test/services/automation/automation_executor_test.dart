import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/automation/automation_executor.dart';
import 'package:shakedown_core/services/automation/automation_step.dart';

void main() {
  test(
    'executor dispatches random-play, settings, and screensaver steps',
    () async {
      final log = <String>[];

      final executor = AutomationExecutor(
        playRandomShow: () async => log.add('dice'),
        delay: (duration) async => log.add('sleep:${duration.inSeconds}'),
        applySetting: (key, value) async => log.add('setting:$key=$value'),
        launchScreensaver: () async => log.add('screensaver'),
      );

      await executor.execute(<AutomationStep>[
        const AutomationStep.playRandomShow(),
        const AutomationStep.sleep(seconds: 2),
        const AutomationStep.setSetting(key: 'force_tv', value: 'true'),
        const AutomationStep.launchScreensaver(),
      ]);

      expect(log, <String>[
        'dice',
        'sleep:2',
        'setting:force_tv=true',
        'screensaver',
      ]);
    },
  );
}
