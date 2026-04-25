import 'dart:async';
import 'package:shakedown_core/services/automation/automation_step.dart';

typedef AutomationDelay = Future<void> Function(Duration duration);
typedef ApplyAutomationSetting = Future<void> Function(String key, String value);
typedef LaunchAutomationScreensaver = Future<void> Function();

class AutomationExecutor {
  final Future<void> Function() playRandomShow;
  final AutomationDelay delay;
  final ApplyAutomationSetting applySetting;
  final LaunchAutomationScreensaver launchScreensaver;

  const AutomationExecutor({
    required this.playRandomShow,
    required this.delay,
    required this.applySetting,
    required this.launchScreensaver,
  });

  Future<void> execute(List<AutomationStep> steps) async {
    for (final step in steps) {
      switch (step.type) {
        case AutomationStepType.playRandomShow:
          await playRandomShow();
        case AutomationStepType.sleep:
          await delay(Duration(seconds: step.seconds ?? 0));
        case AutomationStepType.setSetting:
          await applySetting(step.key ?? '', step.value ?? '');
        case AutomationStepType.launchScreensaver:
          await launchScreensaver();
      }
    }
  }
}
