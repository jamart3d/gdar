# Unify App Orchestration Phase 1A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the shared root provider graph into `shakedown_core` so mobile, TV, and web can reuse the same provider composition without centralizing app-shell behavior.

**Architecture:** Introduce a shared provider builder plus typed overrides in `packages/shakedown_core/lib/app/`. Keep all app bootstrap, `MaterialApp`, route observers, and theme shell logic in app-local `main.dart` files.

**Tech Stack:** Flutter, Dart, Provider, `shared_preferences`, package imports from `shakedown_core`

---

## Scope

### In Scope
- Shared provider builder
- Typed provider override object
- Targeted provider composition test

### Non-Goals
- Do not edit app entrypoints in this phase
- Do not add automation parsing/execution code
- Do not centralize bootstrap concerns

### Write Scope
- Create: `packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart`
- Create: `packages/shakedown_core/lib/app/gdar_app_providers.dart`
- Create: `packages/shakedown_core/test/app/gdar_app_providers_test.dart`

### Invariants
- Preserve provider dependency order
- Preserve `ProxyProvider` wiring shape
- Support injected test doubles and app-owned provider instances

## Task 1: Add the Typed Overrides Object

**Files:**
- Create: `packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart`

- [ ] **Step 1: Implement the typed override container**

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

- [ ] **Step 2: Run analyzer on the new file**

Run: `dart analyze packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart`
Expected: PASS

## Task 2: Add the Shared Provider Builder

**Files:**
- Create: `packages/shakedown_core/lib/app/gdar_app_providers.dart`

- [ ] **Step 1: Implement the shared provider builder**

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

- [ ] **Step 2: Run analyzer on the provider builder**

Run: `dart analyze packages/shakedown_core/lib/app/gdar_app_providers.dart`
Expected: PASS

## Task 3: Add a Focused Provider Composition Test

**Files:**
- Create: `packages/shakedown_core/test/app/gdar_app_providers_test.dart`

- [ ] **Step 1: Write the failing test**

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

- [ ] **Step 2: Run the focused test**

Run: `flutter test packages/shakedown_core/test/app/gdar_app_providers_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/app/gdar_app_provider_overrides.dart packages/shakedown_core/lib/app/gdar_app_providers.dart packages/shakedown_core/test/app/gdar_app_providers_test.dart
git commit -m "refactor: extract shared app provider graph"
```

## Handoff

Save results to:
- `reports/2026-04-25_worker_a_provider_graph_handoff.md`

Required contents:
- Status
- Files changed
- Commands run
- Results
- Risks
- Open questions
