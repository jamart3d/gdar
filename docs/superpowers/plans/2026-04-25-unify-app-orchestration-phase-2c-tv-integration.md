# Unify App Orchestration Phase 2C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace TV inline provider wiring with the shared provider builder and migrate TV automation handling to the shared parser/executor.

**Architecture:** TV keeps app-local route observer setup, screensaver launch flow, and bootstrap behavior. Shared code is limited to provider composition and typed automation execution.

**Tech Stack:** Flutter, Dart, Provider, package imports from `shakedown_core`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1a-provider-graph.md`
- Requires `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1b-automation-core.md`

## Scope

### Write Scope
- Modify: `apps/gdar_tv/lib/main.dart`

### Invariants
- Preserve `lockIsTv`
- Preserve TV route observer wiring
- Preserve TV screensaver launch behavior
- Do not centralize bootstrap logic

## Task 1: Swap TV to the Shared Provider Builder

**Files:**
- Modify: `apps/gdar_tv/lib/main.dart`

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
      deviceService: widget.deviceService ??
          DeviceService(initialIsTv: widget.isTv, lockIsTv: widget.isTv),
      screensaverLaunchDelegate: ScreensaverLaunchDelegate(({
        bool allowPermissionPrompts = true,
      }) {
        return _launchScreensaver(
          allowPermissionPrompts: allowPermissionPrompts,
          source: 'manual',
        );
      }),
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

Run: `dart analyze apps/gdar_tv/lib/main.dart`
Expected: PASS

## Task 2: Migrate TV Automation to Shared Parser/Executor

**Files:**
- Modify: `apps/gdar_tv/lib/main.dart`

- [ ] **Step 1: Replace inline parsing**

```dart
if (uri.path == 'automate' || uri.host == 'automate') {
  final rawSteps = uri.queryParameters['steps']?.split(',') ?? <String>[];
  _handleAutomation(parseAutomationSteps(rawSteps));
}
```

- [ ] **Step 2: Replace `_handleAutomation` branching with `AutomationExecutor`**

```dart
Future<void> _handleAutomation(List<AutomationStep> steps) async {
  final context = _navigatorKey.currentState?.context;
  if (context == null) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _handleAutomation(steps);
    });
    return;
  }

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
    launchScreensaver: () => _launchScreensaver(
      allowPermissionPrompts: true,
      source: 'automation',
    ),
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

Run: `flutter analyze apps/gdar_tv`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_tv/lib/main.dart
git commit -m "refactor: share tv app orchestration"
```

## Handoff

Save results to:
- `reports/2026-04-25_worker_e_tv_integration_handoff.md`
