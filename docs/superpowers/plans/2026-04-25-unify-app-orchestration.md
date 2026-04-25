# Unify App Orchestration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce duplicated app-entry orchestration by centralizing the shared provider graph across mobile, TV, and web, while extracting shared deep-link automation execution for mobile and TV without changing web behavior.

**Architecture:** Keep app bootstrap and app-shell ownership inside each target `main.dart`, but move shared provider construction into `packages/shakedown_core`. Extend the existing deep-link seam by adding a shared automation parser/executor instead of introducing a second orchestration abstraction beside `DeepLinkService`.

**Tech Stack:** Flutter, Dart, Provider (`MultiProvider`, `ChangeNotifierProxyProvider`), `shared_preferences`, `app_links`, package imports from `shakedown_core`

---

## Scope

### In Scope
- Unify the repeated provider graph used by:
  - `apps/gdar_mobile/lib/main.dart`
  - `apps/gdar_tv/lib/main.dart`
  - `apps/gdar_web/lib/main.dart`
- Extract shared automation-step parsing and execution used by:
  - `apps/gdar_mobile/lib/main.dart`
  - `apps/gdar_tv/lib/main.dart`
- Add targeted tests for provider composition and automation behavior.

### Explicit Non-Goals
- Do not centralize `main()` bootstrap tasks such as orientation locks, `JustAudioBackground.init`, or web-only startup logging.
- Do not replace app-specific `MaterialApp` configuration, route observers, or theme-shell branching.
- Do not add web automation parity in this change. Web deep links remain functionally unchanged.
- Do not weaken platform rules:
  - TV keeps `lockIsTv: widget.isTv`
  - mobile keeps conditional `ScreensaverLaunchDelegate` registration
  - web keeps Fruit/Android shell selection in app code

### Invariants To Preserve
- Provider initialization order must remain compatible with the current `ProxyProvider` dependency chain.
- `ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider)` remains app-local and must still happen before theme-driven UI uses settings.
- Mobile must retain `shakedown://settings?...` handling.
- TV screensaver launch path and route-observer behavior must stay local to TV.

### Current Files To Study Before Editing
- `apps/gdar_mobile/lib/main.dart`
- `apps/gdar_tv/lib/main.dart`
- `apps/gdar_web/lib/main.dart`
- `packages/shakedown_core/lib/services/deep_link_service.dart`
- `packages/shakedown_core/lib/services/device_service.dart`
- `packages/shakedown_core/lib/services/screensaver_launch_delegate.dart`
- `packages/shakedown_core/lib/providers/audio_provider.dart`
- `packages/shakedown_core/lib/providers/show_list_provider.dart`
- `packages/shakedown_core/lib/providers/theme_provider.dart`

## File Structure

### New Files
- `packages/shakedown_core/lib/app/gdar_app_providers.dart`
  - Shared builder for the common provider graph.
- `packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart`
  - Typed configuration for injected providers and per-platform switches.
- `packages/shakedown_core/lib/services/automation/automation_step.dart`
  - Value model for parsed automation steps.
- `packages/shakedown_core/lib/services/automation/automation_step_parser.dart`
  - Parses `steps=` deep-link payload entries.
- `packages/shakedown_core/lib/services/automation/automation_executor.dart`
  - Executes parsed steps against app-owned callbacks/providers.
- `packages/shakedown_core/test/app/gdar_app_providers_test.dart`
  - Verifies provider composition and overrides.
- `packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
  - Verifies parsing behavior.
- `packages/shakedown_core/test/services/automation/automation_executor_test.dart`
  - Verifies execution behavior with fakes.

### Modified Files
- `apps/gdar_mobile/lib/main.dart`
- `apps/gdar_tv/lib/main.dart`
- `apps/gdar_web/lib/main.dart`

## Task 1: Extract the Shared Provider Graph

**Files:**
- Create: `packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart`
- Create: `packages/shakedown_core/lib/app/gdar_app_providers.dart`
- Test: `packages/shakedown_core/test/app/gdar_app_providers_test.dart`

- [ ] **Step 1: Write the failing provider-composition test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildGdarAppProviders wires shared dependencies', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs, isTv: true);
    final showListProvider = ShowListProvider();
    final audioCacheService = AudioCacheService();
    final deviceService = DeviceService(initialIsTv: true, lockIsTv: true);
    const screensaverDelegate = ScreensaverLaunchDelegate(_noopLaunch);

    await tester.pumpWidget(
      MultiProvider(
        providers: buildGdarAppProviders(
          prefs: prefs,
          isTv: true,
          overrides: GdarAppProviderOverrides(
            settingsProvider: settingsProvider,
            showListProvider: showListProvider,
            audioCacheService: audioCacheService,
            deviceService: deviceService,
            screensaverLaunchDelegate: screensaverDelegate,
          ),
        ),
        child: Builder(
          builder: (context) {
            expect(context.read<SettingsProvider>(), same(settingsProvider));
            expect(context.read<ShowListProvider>(), same(showListProvider));
            expect(context.read<AudioCacheService>(), same(audioCacheService));
            expect(context.read<DeviceService>(), same(deviceService));
            expect(context.read<ScreensaverLaunchDelegate>(), screensaverDelegate);
            expect(context.read<ThemeProvider>().isTv, isTrue);
            expect(context.read<AudioProvider>(), isNotNull);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}

Future<void> _noopLaunch({bool allowPermissionPrompts = true}) async {}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test packages/shakedown_core/test/app/gdar_app_providers_test.dart`
Expected: FAIL with missing imports or undefined `buildGdarAppProviders` / `GdarAppProviderOverrides`.

- [ ] **Step 3: Implement the typed override model**

```dart
import 'package:flutter/widgets.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';

@immutable
class GdarAppProviderOverrides {
  final SettingsProvider? settingsProvider;
  final ShowListProvider? showListProvider;
  final AudioProvider? audioProvider;
  final AudioCacheService? audioCacheService;
  final DeviceService? deviceService;
  final ScreensaverLaunchDelegate? screensaverLaunchDelegate;

  const GdarAppProviderOverrides({
    this.settingsProvider,
    this.showListProvider,
    this.audioProvider,
    this.audioCacheService,
    this.deviceService,
    this.screensaverLaunchDelegate,
  });
}
```

- [ ] **Step 4: Implement the shared provider builder**

```dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/services/wakelock_service.dart';

List<SingleChildWidget> buildGdarAppProviders({
  required SharedPreferences prefs,
  required bool isTv,
  required GdarAppProviderOverrides overrides,
}) {
  final settingsProvider =
      overrides.settingsProvider ?? SettingsProvider(prefs, isTv: isTv);
  final showListProvider = overrides.showListProvider ?? ShowListProvider();

  return <SingleChildWidget>[
    ChangeNotifierProvider(create: (_) => ThemeProvider(isTv: isTv)),
    Provider<CatalogService>(create: (_) => CatalogService()),
    Provider<WakelockService>(create: (_) => WakelockService()),
    ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
    ChangeNotifierProvider<AudioCacheService>(
      create: (_) => overrides.audioCacheService ?? (AudioCacheService()..init()),
    ),
    ChangeNotifierProxyProvider<SettingsProvider, ShowListProvider>(
      create: (_) => showListProvider,
      update: (_, settings, current) => current!..update(settings),
    ),
    ChangeNotifierProxyProvider3<
      ShowListProvider,
      SettingsProvider,
      AudioCacheService,
      AudioProvider
    >(
      create: (_) => overrides.audioProvider ?? AudioProvider(),
      update: (_, shows, settings, cache, current) {
        return current!..update(shows, settings, cache);
      },
    ),
    ChangeNotifierProvider(create: (_) => UpdateProvider()),
    ChangeNotifierProvider<DeviceService>(
      create: (_) => overrides.deviceService ?? DeviceService(initialIsTv: isTv),
    ),
    if (overrides.screensaverLaunchDelegate != null)
      Provider<ScreensaverLaunchDelegate>.value(
        value: overrides.screensaverLaunchDelegate!,
      ),
  ];
}
```

- [ ] **Step 5: Run the provider-composition test to verify it passes**

Run: `flutter test packages/shakedown_core/test/app/gdar_app_providers_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart packages/shakedown_core/lib/app/gdar_app_providers.dart packages/shakedown_core/test/app/gdar_app_providers_test.dart
git commit -m "refactor: extract shared app provider graph"
```

## Task 2: Refactor Mobile, TV, and Web to Use the Shared Provider Builder

**Files:**
- Modify: `apps/gdar_mobile/lib/main.dart`
- Modify: `apps/gdar_tv/lib/main.dart`
- Modify: `apps/gdar_web/lib/main.dart`
- Test: existing target-level widget tests if present; otherwise rely on `flutter analyze` plus app-specific smoke tests in later tasks

- [ ] **Step 1: Replace the inline provider graph in mobile with the shared builder**

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
      // existing MaterialApp tree stays here
    },
  ),
);
```

- [ ] **Step 2: Replace the inline provider graph in TV with the shared builder, preserving `lockIsTv`**

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
      // existing MaterialApp tree stays here
    },
  ),
);
```

- [ ] **Step 3: Replace the inline provider graph in web with the shared builder without adding automation or screensaver delegate**

```dart
return MultiProvider(
  providers: buildGdarAppProviders(
    prefs: widget.prefs,
    isTv: _isTv,
    overrides: GdarAppProviderOverrides(
      settingsProvider: _settingsProvider,
      showListProvider: _showListProvider,
    ),
  ),
  child: Consumer2<ThemeProvider, SettingsProvider>(
    builder: (context, themeProvider, settingsProvider, child) {
      // existing Fruit/Android shell branching stays here
    },
  ),
);
```

- [ ] **Step 4: Run analysis to catch missing imports, generic mismatches, and lifecycle regressions**

Run: `melos run analyze`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_mobile/lib/main.dart apps/gdar_tv/lib/main.dart apps/gdar_web/lib/main.dart
git commit -m "refactor: share root provider graph across apps"
```

## Task 3: Extract Shared Automation Step Parsing

**Files:**
- Create: `packages/shakedown_core/lib/services/automation/automation_step.dart`
- Create: `packages/shakedown_core/lib/services/automation/automation_step_parser.dart`
- Test: `packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`

- [ ] **Step 1: Write the failing parser test**

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

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
Expected: FAIL with undefined parser/model symbols.

- [ ] **Step 3: Implement the automation step model and parser**

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

- [ ] **Step 4: Run the parser test to verify it passes**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/services/automation/automation_step.dart packages/shakedown_core/lib/services/automation/automation_step_parser.dart packages/shakedown_core/test/services/automation/automation_step_parser_test.dart
git commit -m "refactor: extract automation step parser"
```

## Task 4: Extract Shared Automation Execution

**Files:**
- Create: `packages/shakedown_core/lib/services/automation/automation_executor.dart`
- Test: `packages/shakedown_core/test/services/automation/automation_executor_test.dart`

- [ ] **Step 1: Write the failing executor test**

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

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_executor_test.dart`
Expected: FAIL with undefined `AutomationExecutor`.

- [ ] **Step 3: Implement the shared executor**

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

- [ ] **Step 4: Run the executor test to verify it passes**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_executor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/services/automation/automation_executor.dart packages/shakedown_core/test/services/automation/automation_executor_test.dart
git commit -m "refactor: extract automation executor"
```

## Task 5: Migrate Mobile Automation to the Shared Parser/Executor

**Files:**
- Modify: `apps/gdar_mobile/lib/main.dart`

- [ ] **Step 1: Replace inline step parsing in mobile with the shared parser**

```dart
void _initDeepLinks() {
  _deepLinkService = widget.deepLinkService ?? DeepLinkService();
  _deepLinkService!.init();

  _linkSubscription = _deepLinkService!.uriStream.listen((Uri? uri) async {
    if (uri == null || uri.scheme != 'shakedown') {
      return;
    }

    if (uri.path == 'automate' || uri.host == 'automate') {
      final rawSteps = uri.queryParameters['steps']?.split(',') ?? <String>[];
      await _handleAutomation(parseAutomationSteps(rawSteps));
      return;
    }

    if (uri.host == 'settings') {
      await _handleSettingsDeepLink(uri);
    }
  });
}
```

- [ ] **Step 2: Replace inline branching in `_handleAutomation` with `AutomationExecutor`**

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

- [ ] **Step 3: Add a dedicated helper for shared settings mutations**

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

- [ ] **Step 4: Run analysis focused on the mobile app**

Run: `flutter analyze apps/gdar_mobile`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_mobile/lib/main.dart
git commit -m "refactor: share mobile automation execution"
```

## Task 6: Migrate TV Automation to the Shared Parser/Executor

**Files:**
- Modify: `apps/gdar_tv/lib/main.dart`

- [ ] **Step 1: Replace TV step parsing with the shared parser**

```dart
void _initDeepLinks() {
  _deepLinkService = widget.deepLinkService ?? DeepLinkService();
  _deepLinkService!.init();

  _linkSubscription = _deepLinkService!.uriStream.listen((Uri? uri) {
    if (uri == null || uri.scheme != 'shakedown') {
      return;
    }

    if (uri.path == 'automate' || uri.host == 'automate') {
      final rawSteps = uri.queryParameters['steps']?.split(',') ?? <String>[];
      _handleAutomation(parseAutomationSteps(rawSteps));
    }
  });
}
```

- [ ] **Step 2: Replace TV inline automation branching with the shared executor**

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

- [ ] **Step 3: Reuse the same `_applyAutomationSetting` helper shape used by mobile**

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

- [ ] **Step 4: Run analysis focused on the TV app**

Run: `flutter analyze apps/gdar_tv`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_tv/lib/main.dart
git commit -m "refactor: share tv automation execution"
```

## Task 7: Verify Cross-App Behavior and Guard Against Regressions

**Files:**
- Modify only if verification exposes breakage

- [ ] **Step 1: Run the targeted `shakedown_core` tests**

Run: `flutter test packages/shakedown_core/test/app/gdar_app_providers_test.dart packages/shakedown_core/test/services/automation/automation_step_parser_test.dart packages/shakedown_core/test/services/automation/automation_executor_test.dart`
Expected: PASS

- [ ] **Step 2: Run the full monorepo test suite**

Run: `melos run test`
Expected: PASS

- [ ] **Step 3: Run the full monorepo analyzer**

Run: `melos run analyze`
Expected: PASS

- [ ] **Step 4: Perform manual smoke checks**

Run:
- Mobile: launch app, verify boot succeeds, play a random show, confirm settings-driven screensaver behavior still works on phone vs forced-TV mode.
- TV: launch app, trigger `shakedown://automate?steps=dice,sleep:1,screensaver`, confirm route stack remains stable and screensaver opens.
- Web: launch app, confirm no startup regression, Fruit shell still renders, and deep-link behavior is unchanged.

Expected:
- No provider lookup exceptions
- No `ProxyProvider` null/update ordering failures
- No loss of TV `lockIsTv` behavior
- No accidental web automation implementation

- [ ] **Step 5: Final commit**

```bash
git add .
git commit -m "refactor: unify app orchestration"
```

## Open Questions To Resolve During Implementation

1. `AudioCacheService` is created as a `ChangeNotifierProvider` in all apps and initialized with `..init()`. Confirm whether repeated initialization is acceptable when injected test doubles are used.
2. Decide whether `_applyAutomationSetting` should stay duplicated in mobile/TV for now or be extracted later into a second shared helper once the executor migration lands safely.
3. Confirm whether web should eventually gain `shakedown://automate` support in a follow-up plan rather than in this refactor.

## Self-Review

### Spec Coverage
- Shared provider graph extraction: covered by Tasks 1-2.
- Shared automation extraction: covered by Tasks 3-6.
- Verification and regression control: covered by Task 7.
- Web scope clarity: documented as a non-goal for automation.

### Placeholder Scan
- No `TODO`, `TBD`, or “implement later” markers remain.
- Each code-changing step includes concrete file paths and code sketches.
- Each verification step includes explicit commands and expected outcomes.

### Type Consistency
- Provider extraction consistently uses `buildGdarAppProviders` and `GdarAppProviderOverrides`.
- Automation extraction consistently uses `AutomationStep`, `parseAutomationSteps`, and `AutomationExecutor`.
- TV/mobile preserve app-owned launch behavior while sharing parsing and execution infrastructure.
