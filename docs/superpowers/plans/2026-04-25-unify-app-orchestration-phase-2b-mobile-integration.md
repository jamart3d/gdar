# Unify App Orchestration Phase 2B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace mobile inline provider wiring with the shared provider builder and migrate mobile automation handling to the shared parser/executor.

**Architecture:** Mobile keeps app-local bootstrap, `MaterialApp`, settings deep-link handling, and screensaver launch behavior. Shared code is limited to provider composition and typed automation execution.

**Tech Stack:** Flutter, Dart, Provider, package imports from `shakedown_core`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1a-provider-graph.md`
- Requires `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1b-automation-core.md`

## Scope

### Write Scope
- Modify: `apps/gdar_mobile/lib/main.dart`

### Invariants
- Preserve `shakedown://settings?...` handling
- Preserve conditional screensaver behavior for non-TV vs TV
- Preserve app-local `ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider)`
- Do not centralize bootstrap or screensaver launch logic

## Task 1: Swap Mobile to the Shared Provider Builder

**Files:**
- Modify: `apps/gdar_mobile/lib/main.dart`

- [ ] **Step 1: Replace the inline provider list**

```dart
return MultiProvider(
  providers: buildGdarAppProviders(
    prefs: widget.prefs,
    isTv: widget.isTv,
    overrides: GdarAppProviderOverrides(
      settingsProvider: _settingsProvider,
      showListProvider: _showListProvider,
      audioProvider: widget.audioProvider,
      audioCacheService: widget.audioCacheService,
      deviceService: widget.deviceService,
      screensaverLaunchDelegate: widget.isTv
          ? ScreensaverLaunchDelegate(({
              bool allowPermissionPrompts = true,
            }) {
              return _launchScreensaver(
                allowPermissionPrompts: allowPermissionPrompts,
                source: 'manual',
              );
            })
          : null,
    ),
  ),
  child: Consumer2<ThemeProvider, SettingsProvider>(
    builder: (context, themeProvider, settingsProvider, child) {
      // Keep the existing MaterialApp tree here.
    },
  ),
);
```

- [ ] **Step 2: Run analysis**

Run: `dart analyze apps/gdar_mobile/lib/main.dart`
Expected: PASS

## Task 2: Migrate Mobile Automation to Shared Parser/Executor

**Files:**
- Modify: `apps/gdar_mobile/lib/main.dart`

- [ ] **Step 1: Replace inline parsing in `_initDeepLinks()`**

```dart
if (uri.path == 'automate' || uri.host == 'automate') {
  final rawSteps = uri.queryParameters['steps']?.split(',') ?? <String>[];
  await _handleAutomation(parseAutomationSteps(rawSteps));
  return;
}
```

- [ ] **Step 2: Replace `_handleAutomation` branching with `AutomationExecutor`**

```dart
Future<void> _handleAutomation(List<AutomationStep> steps) async {
  final state = _navigatorKey.currentState;
  if (state == null) {
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _handleAutomation(steps),
    );
    return;
  }

  final context = state.context;
  final audioProvider = Provider.of<AudioProvider>(context, listen: false);
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

  final executor = AutomationExecutor(
    playRandomShow: audioProvider.playRandomShow,
    delay: Future<void>.delayed,
    applySetting: (key, value) => _applyAutomationSetting(
      settingsProvider: settingsProvider,
      key: key,
      value: value,
    ),
    launchScreensaver: () async {
      if (widget.isTv) {
        await _launchScreensaver(
          allowPermissionPrompts: true,
          source: 'automation',
        );
      } else if (context.mounted) {
        await ScreensaverScreen.show(context);
      }
    },
  );

  await executor.execute(steps);
}
```

- [ ] **Step 3: Add a local helper for settings application**

```dart
Future<void> _applyAutomationSetting({
  required SettingsProvider settingsProvider,
  required String key,
  required String value,
}) async {
  if (key == 'oil_enable_audio_reactivity') {
    final target = value == 'true';
    if (settingsProvider.oilEnableAudioReactivity != target) {
      await settingsProvider.toggleOilEnableAudioReactivity();
    }
    return;
  }

  if (key == 'oil_audio_graph_mode') {
    await settingsProvider.setOilAudioGraphMode(value);
    return;
  }

  if (key == 'force_tv') {
    await settingsProvider.setForceTv(value == 'true');
    return;
  }

  if (key == 'oil_screensaver_mode') {
    await settingsProvider.setOilScreensaverMode(value);
  }
}
```

- [ ] **Step 4: Run focused analysis**

Run: `flutter analyze apps/gdar_mobile`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_mobile/lib/main.dart
git commit -m "refactor: share mobile app orchestration"
```

## Handoff

Save results to:
- `reports/2026-04-25_worker_d_mobile_integration_handoff.md`
