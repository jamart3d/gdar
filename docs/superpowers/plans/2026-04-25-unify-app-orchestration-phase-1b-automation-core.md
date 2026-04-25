# Unify App Orchestration Phase 1B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract reusable automation parsing and execution infrastructure for the mobile and TV `shakedown://automate` flow.

**Architecture:** Add typed automation primitives under `packages/shakedown_core/lib/services/automation/`, but keep deep-link ingestion and app-owned settings/screensaver behavior in the app entrypoints.

**Tech Stack:** Flutter, Dart, package imports from `shakedown_core`

---

## Scope

### In Scope
- typed automation step model
- parser from raw `steps=` values
- executor that dispatches typed steps to injected callbacks
- targeted parser and executor tests

### Non-Goals
- do not edit `DeepLinkService`
- do not edit app entrypoints
- do not add web automation behavior

### Write Scope
- Create: `packages/shakedown_core/lib/services/automation/automation_step.dart`
- Create: `packages/shakedown_core/lib/services/automation/automation_step_parser.dart`
- Create: `packages/shakedown_core/lib/services/automation/automation_executor.dart`
- Create: `packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
- Create: `packages/shakedown_core/test/services/automation/automation_executor_test.dart`

## Task 1: Add the Step Model

**Files:**
- Create: `packages/shakedown_core/lib/services/automation/automation_step.dart`

- [ ] **Step 1: Implement the automation step model**

```dart
enum AutomationStepType {
  playRandomShow,
  sleep,
  setSetting,
  launchScreensaver,
}

class AutomationStep {
  final AutomationStepType type;
  final int? seconds;
  final String? key;
  final String? value;

  const AutomationStep._({
    required this.type,
    this.seconds,
    this.key,
    this.value,
  });

  const AutomationStep.playRandomShow()
      : this._(type: AutomationStepType.playRandomShow);

  const AutomationStep.sleep({required int seconds})
      : this._(type: AutomationStepType.sleep, seconds: seconds);

  const AutomationStep.setSetting({required String key, required String value})
      : this._(
          type: AutomationStepType.setSetting,
          key: key,
          value: value,
        );

  const AutomationStep.launchScreensaver()
      : this._(type: AutomationStepType.launchScreensaver);
}
```

- [ ] **Step 2: Analyze the new model**

Run: `dart analyze packages/shakedown_core/lib/services/automation/automation_step.dart`
Expected: PASS

## Task 2: Add the Parser and Test

**Files:**
- Create: `packages/shakedown_core/lib/services/automation/automation_step_parser.dart`
- Create: `packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`

- [ ] **Step 1: Write the parser test**

```dart
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

    expect(
      steps,
      <AutomationStep>[
        const AutomationStep.playRandomShow(),
        const AutomationStep.sleep(seconds: 3),
        const AutomationStep.setSetting(key: 'force_tv', value: 'true'),
        const AutomationStep.launchScreensaver(),
      ],
    );
  });
}
```

- [ ] **Step 2: Implement the parser**

```dart
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
```

- [ ] **Step 3: Run the parser test**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
Expected: PASS

## Task 3: Add the Executor and Test

**Files:**
- Create: `packages/shakedown_core/lib/services/automation/automation_executor.dart`
- Create: `packages/shakedown_core/test/services/automation/automation_executor_test.dart`

- [ ] **Step 1: Write the executor test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/automation/automation_executor.dart';
import 'package:shakedown_core/services/automation/automation_step.dart';

void main() {
  test('executor dispatches random-play, settings, and screensaver steps', () async {
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

    expect(
      log,
      <String>[
        'dice',
        'sleep:2',
        'setting:force_tv=true',
        'screensaver',
      ],
    );
  });
}
```

- [ ] **Step 2: Implement the executor**

```dart
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
```

- [ ] **Step 3: Run the focused tests**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/services/automation/automation_executor_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add packages/shakedown_core/lib/services/automation/automation_step.dart packages/shakedown_core/lib/services/automation/automation_step_parser.dart packages/shakedown_core/lib/services/automation/automation_executor.dart packages/shakedown_core/test/services/automation/automation_step_parser_test.dart packages/shakedown_core/test/services/automation/automation_executor_test.dart
git commit -m "refactor: extract automation core"
```

## Handoff

Save results to:
- `reports/2026-04-25_worker_b_automation_core_handoff.md`
