# PWA Power Playback Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Model routing:** If using subagents, use `gpt-5.4-mini` for Tasks 1, 2, 4, 5, 7, and 8. Use `gpt-5.4` with medium reasoning for Tasks 3 and 6 because they touch provider lifecycle, conditional web interop, and diagnostics contracts. Do not hand the entire plan to one mini agent; execute one task per worker and review between tasks.

**Goal:** Add Android/iOS PWA power-aware playback profiles so battery sessions maximize survival and charging sessions prioritize true gapless long playback.

**Architecture:** Keep one selected JS strategy for PWA sessions: Hybrid. Hybrid already starts with HTML5 for instant playback and can be configured to stay HTML5-like or hand off to Web Audio. Add a small Dart policy layer that maps `auto`, `batterySaver`, `chargingGapless`, and `custom` to existing engine knobs, plus a web-only battery/charging bridge that uses Battery Status API when available and falls back to battery-safe behavior when unavailable.

**Tech Stack:** Flutter/Dart Provider, SharedPreferences, Dart JS interop, web package, custom JS audio engines under `apps/gdar_web/web`, Node regression tests, Flutter unit tests.

---

## File Structure

- Create: `packages/shakedown_core/lib/services/audio/web_playback_power_policy.dart`
  - Pure Dart policy resolver. No Flutter or JS dependency. Unit-testable in the Dart VM.
- Create: `packages/shakedown_core/lib/utils/web_power_state.dart`
  - Conditional export wrapper for web power state.
- Create: `packages/shakedown_core/lib/utils/web_power_state_stub.dart`
  - Non-web fallback returning unknown charging state.
- Create: `packages/shakedown_core/lib/utils/web_power_state_web.dart`
  - Web JS interop wrapper for `window._gdarPowerState`.
- Create: `apps/gdar_web/web/web_power_state.js`
  - Browser-side Battery Status API bridge. Dispatches `gdar-power-state-change`.
- Modify: `apps/gdar_web/web/index.html`
  - Load `web_power_state.js` before engine selection.
- Modify: `apps/gdar_web/web/hybrid_init.js`
  - Prefer Hybrid for installed Android/iOS PWAs so power profiles can adjust runtime handoff/background knobs without requiring an engine relaunch.
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
  - Import `dart:async`, policy, and web power state utilities. Add `dispose()` cleanup.
- Modify: `packages/shakedown_core/lib/providers/settings_provider_web.dart`
  - Add `WebPlaybackPowerProfile` preference, detected charging field, profile application, and custom-mode escape hatch for advanced manual settings.
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
  - Load the new power profile preference, start the web charging listener, apply safe defaults.
- Modify: `packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart`
  - Push profile-controlled runtime changes to the active web engine.
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`
  - Add a Fruit-compatible power profile selector above advanced engine knobs.
- Modify: `apps/gdar_web/web/audio_heartbeat.js`
  - Expose heartbeat blocked count and last blocked reason in a stable getter.
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
  - Add optional JS interop for heartbeat diagnostic state.
- Modify: `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`
  - Add HUD fields for resolved power profile and heartbeat blocked count.
- Modify: `docs/WEB_PLAYBACK_DECISION_TREE.md`
  - Reconcile docs with actual policy.
- Modify: `apps/gdar_web/docs/first_run_presets.md`
  - Reconcile first-run docs with actual policy.
- Test: `packages/shakedown_core/test/services/web_playback_power_policy_test.dart`
- Test: `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
- Test: `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`
- Test: `apps/gdar_web/web/tests/pwa_strategy_regression.js`
- Test: `apps/gdar_web/web/tests/visibility_regression.js`
- Test runner: `apps/gdar_web/web/tests/run_tests.js`

---

## Policy Contract

Resolved profiles:

| User Profile | Resolved Source | Engine | Handoff | Background | Hidden WA | Prevent Sleep | Prefetch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `auto` + charging detected | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60` |
| `auto` + battery detected | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30` |
| `auto` + Battery API unavailable | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30` |
| `batterySaver` | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30` |
| `chargingGapless` | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60` |
| `custom` | `custom` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

Rationale:

- Battery sessions avoid Web Audio handoff and run Hybrid as an HTML5-like shell with video survival.
- Charging sessions keep Hybrid so the app still starts via HTML5, then immediately hands off to Web Audio for true gapless precision.
- `video` is used for both PWA modes because Android/iOS PWA longevity is the target and the user explicitly prioritizes long sessions.
- `custom` prevents automatic power detection from overwriting manually tuned advanced settings.

---

### Task 1: Add Pure Power Policy

**Files:**
- Create: `packages/shakedown_core/lib/services/audio/web_playback_power_policy.dart`
- Test: `packages/shakedown_core/test/services/web_playback_power_policy_test.dart`

- [ ] **Step 1: Write the failing policy tests**

Create `packages/shakedown_core/test/services/web_playback_power_policy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

void main() {
  group('resolveWebPlaybackPowerPolicy', () {
    test('auto falls back to battery-safe when charging state is unknown', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.auto,
        detectedCharging: null,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.battery);
      expect(config.audioEngineMode, AudioEngineMode.hybrid);
      expect(config.handoffMode, HybridHandoffMode.none);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isFalse);
      expect(config.preventSleep, isFalse);
      expect(config.webPrefetchSeconds, 30);
      expect(config.applyEngineSettings, isTrue);
    });

    test('auto resolves to charging gapless when charging is detected', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.auto,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.charging);
      expect(config.audioEngineMode, AudioEngineMode.hybrid);
      expect(config.handoffMode, HybridHandoffMode.immediate);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isTrue);
      expect(config.preventSleep, isTrue);
      expect(config.webPrefetchSeconds, 60);
      expect(config.applyEngineSettings, isTrue);
    });

    test('batterySaver always resolves to battery-safe profile', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.batterySaver,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.battery);
      expect(config.handoffMode, HybridHandoffMode.none);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isFalse);
      expect(config.preventSleep, isFalse);
      expect(config.webPrefetchSeconds, 30);
    });

    test('chargingGapless always resolves to charging profile', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.chargingGapless,
        detectedCharging: false,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.charging);
      expect(config.handoffMode, HybridHandoffMode.immediate);
      expect(config.backgroundMode, HybridBackgroundMode.video);
      expect(config.allowHiddenWebAudio, isTrue);
      expect(config.preventSleep, isTrue);
      expect(config.webPrefetchSeconds, 60);
    });

    test('custom returns a no-apply config', () {
      final config = resolveWebPlaybackPowerPolicy(
        profile: WebPlaybackPowerProfile.custom,
        detectedCharging: true,
      );

      expect(config.resolvedSource, ResolvedWebPlaybackPowerSource.custom);
      expect(config.applyEngineSettings, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_playback_power_policy_test.dart
```

Expected: FAIL because `web_playback_power_policy.dart`, `WebPlaybackPowerProfile`, and `resolveWebPlaybackPowerPolicy` do not exist.

- [ ] **Step 3: Implement the pure policy**

Create `packages/shakedown_core/lib/services/audio/web_playback_power_policy.dart`:

```dart
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

enum WebPlaybackPowerProfile {
  auto,
  batterySaver,
  chargingGapless,
  custom;

  static WebPlaybackPowerProfile fromString(String? value) {
    return WebPlaybackPowerProfile.values.firstWhere(
      (profile) => profile.name == value,
      orElse: () => WebPlaybackPowerProfile.auto,
    );
  }
}

enum ResolvedWebPlaybackPowerSource {
  battery,
  charging,
  custom,
}

class WebPlaybackPowerPolicyConfig {
  const WebPlaybackPowerPolicyConfig({
    required this.resolvedSource,
    required this.audioEngineMode,
    required this.handoffMode,
    required this.backgroundMode,
    required this.allowHiddenWebAudio,
    required this.preventSleep,
    required this.webPrefetchSeconds,
    required this.applyEngineSettings,
  });

  final ResolvedWebPlaybackPowerSource resolvedSource;
  final AudioEngineMode audioEngineMode;
  final HybridHandoffMode handoffMode;
  final HybridBackgroundMode backgroundMode;
  final bool allowHiddenWebAudio;
  final bool preventSleep;
  final int webPrefetchSeconds;
  final bool applyEngineSettings;
}

WebPlaybackPowerPolicyConfig resolveWebPlaybackPowerPolicy({
  required WebPlaybackPowerProfile profile,
  required bool? detectedCharging,
}) {
  switch (profile) {
    case WebPlaybackPowerProfile.custom:
      return const WebPlaybackPowerPolicyConfig(
        resolvedSource: ResolvedWebPlaybackPowerSource.custom,
        audioEngineMode: AudioEngineMode.hybrid,
        handoffMode: HybridHandoffMode.buffered,
        backgroundMode: HybridBackgroundMode.heartbeat,
        allowHiddenWebAudio: false,
        preventSleep: false,
        webPrefetchSeconds: 30,
        applyEngineSettings: false,
      );
    case WebPlaybackPowerProfile.chargingGapless:
      return _chargingGaplessConfig;
    case WebPlaybackPowerProfile.batterySaver:
      return _batterySaverConfig;
    case WebPlaybackPowerProfile.auto:
      return detectedCharging == true
          ? _chargingGaplessConfig
          : _batterySaverConfig;
  }
}

const _batterySaverConfig = WebPlaybackPowerPolicyConfig(
  resolvedSource: ResolvedWebPlaybackPowerSource.battery,
  audioEngineMode: AudioEngineMode.hybrid,
  handoffMode: HybridHandoffMode.none,
  backgroundMode: HybridBackgroundMode.video,
  allowHiddenWebAudio: false,
  preventSleep: false,
  webPrefetchSeconds: 30,
  applyEngineSettings: true,
);

const _chargingGaplessConfig = WebPlaybackPowerPolicyConfig(
  resolvedSource: ResolvedWebPlaybackPowerSource.charging,
  audioEngineMode: AudioEngineMode.hybrid,
  handoffMode: HybridHandoffMode.immediate,
  backgroundMode: HybridBackgroundMode.video,
  allowHiddenWebAudio: true,
  preventSleep: true,
  webPrefetchSeconds: 60,
  applyEngineSettings: true,
);
```

- [ ] **Step 4: Run policy test to verify it passes**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_playback_power_policy_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/services/audio/web_playback_power_policy.dart packages/shakedown_core/test/services/web_playback_power_policy_test.dart
git commit -m "feat: add web playback power policy"
```

---

### Task 2: Add Web Charging Detection Bridge

**Files:**
- Create: `apps/gdar_web/web/web_power_state.js`
- Modify: `apps/gdar_web/web/index.html`
- Create: `packages/shakedown_core/lib/utils/web_power_state.dart`
- Create: `packages/shakedown_core/lib/utils/web_power_state_stub.dart`
- Create: `packages/shakedown_core/lib/utils/web_power_state_web.dart`
- Test: `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`

- [ ] **Step 1: Add failing static contract tests**

Append this test to `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`:

```dart
  test('web power state bridge is loaded before hybrid engine selection', () {
    final repoRoot = _findRepoRoot();
    final index = File(
      p.join(repoRoot, 'apps', 'gdar_web', 'web', 'index.html'),
    ).readAsStringSync();

    final powerIndex = index.indexOf('web_power_state.js');
    final hybridIndex = index.indexOf('hybrid_init.js');

    expect(powerIndex, greaterThanOrEqualTo(0));
    expect(hybridIndex, greaterThanOrEqualTo(0));
    expect(
      powerIndex,
      lessThan(hybridIndex),
      reason:
          'web_power_state.js must load before hybrid_init.js so diagnostics '
          'and launch-time power state are available before engine selection.',
    );
  });
```

Also append this test:

```dart
  test('web power state bridge exposes charging getter and change event', () {
    final repoRoot = _findRepoRoot();
    final script = File(
      p.join(repoRoot, 'apps', 'gdar_web', 'web', 'web_power_state.js'),
    ).readAsStringSync();

    expect(script, contains('window._gdarPowerState'));
    expect(script, contains('getCharging'));
    expect(script, contains('gdar-power-state-change'));
    expect(script, contains('navigator.getBattery'));
  });
```

- [ ] **Step 2: Run contract test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
```

Expected: FAIL because `web_power_state.js` is not present and `index.html` does not load it.

- [ ] **Step 3: Add browser bridge**

Create `apps/gdar_web/web/web_power_state.js`:

```javascript
(function () {
    'use strict';

    const _log = (window._gdarLogger || console);
    let _battery = null;
    let _charging = null;

    function _emit() {
        try {
            window.dispatchEvent(new CustomEvent('gdar-power-state-change', {
                detail: { charging: _charging },
            }));
        } catch (_) { }
    }

    function _syncFromBattery() {
        if (!_battery) return;
        _charging = !!_battery.charging;
        _emit();
    }

    const api = {
        init: function () {
            if (!navigator.getBattery) {
                _charging = null;
                _log.log('[power] Battery Status API unavailable; using battery-safe profile.');
                _emit();
                return;
            }

            navigator.getBattery().then((battery) => {
                _battery = battery;
                _syncFromBattery();
                battery.addEventListener('chargingchange', _syncFromBattery);
            }).catch((err) => {
                _charging = null;
                _log.warn('[power] Battery Status API failed:', err && err.message);
                _emit();
            });
        },

        getCharging: function () {
            return _charging;
        },
    };

    window._gdarPowerState = api;
    api.init();
})();
```

- [ ] **Step 4: Load bridge before engine selection**

In `apps/gdar_web/web/index.html`, add this script after `audio_logger.js` and before `audio_utils.js`:

```html
  <!-- 0.04 Web power/charging state bridge (Battery Status API when available) -->
  <script src="web_power_state.js"></script>
```

- [ ] **Step 5: Add Dart conditional wrapper**

Create `packages/shakedown_core/lib/utils/web_power_state.dart`:

```dart
import 'web_power_state_stub.dart'
    if (dart.library.js_interop) 'web_power_state_web.dart'
    as impl;

Future<bool?> getInitialWebChargingState() => impl.getInitialWebChargingState();

Stream<bool?> get onWebChargingStateChanged => impl.onWebChargingStateChanged;
```

Create `packages/shakedown_core/lib/utils/web_power_state_stub.dart`:

```dart
Future<bool?> getInitialWebChargingState() async => null;

Stream<bool?> get onWebChargingStateChanged => const Stream<bool?>.empty();
```

Create `packages/shakedown_core/lib/utils/web_power_state_web.dart`:

```dart
import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('_gdarPowerState')
external _GdarPowerState? get _powerState;

@JS()
@anonymous
extension type _GdarPowerState(JSObject _) {
  external JSBoolean? getCharging();
}

@JS()
extension type _PowerEvent(JSObject _) implements JSObject {
  external JSObject? get detail;
}

@JS()
extension type _PowerEventDetail(JSObject _) implements JSObject {
  external JSBoolean? get charging;
}

Future<bool?> getInitialWebChargingState() async {
  try {
    return _powerState?.getCharging()?.toDart;
  } catch (_) {
    return null;
  }
}

Stream<bool?> get onWebChargingStateChanged {
  final controller = StreamController<bool?>.broadcast();
  late JSFunction listener;

  listener = ((JSObject raw) {
    try {
      final detail = _PowerEvent(raw).detail;
      if (detail == null) {
        controller.add(null);
        return;
      }
      controller.add(_PowerEventDetail(detail).charging?.toDart);
    } catch (_) {
      controller.add(null);
    }
  }).toJS;

  web.window.addEventListener('gdar-power-state-change', listener);
  controller.onCancel = () {
    web.window.removeEventListener('gdar-power-state-change', listener);
  };
  return controller.stream;
}
```

- [ ] **Step 6: Run contract test to verify it passes**

Run:

```bash
flutter test packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add apps/gdar_web/web/web_power_state.js apps/gdar_web/web/index.html packages/shakedown_core/lib/utils/web_power_state.dart packages/shakedown_core/lib/utils/web_power_state_stub.dart packages/shakedown_core/lib/utils/web_power_state_web.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
git commit -m "feat: add web charging state bridge"
```

---

### Task 3: Wire Power Profiles Into SettingsProvider

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_web.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Test: `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`

- [ ] **Step 1: Write failing SettingsProvider tests**

Create `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('battery saver profile applies durable HTML5-like hybrid settings', () async {
    SharedPreferences.setMockInitialValues({'first_run_check_done': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs);

    provider.setWebPlaybackPowerProfile(WebPlaybackPowerProfile.batterySaver);

    expect(provider.webPlaybackPowerProfile, WebPlaybackPowerProfile.batterySaver);
    expect(provider.resolvedWebPlaybackPowerSource, ResolvedWebPlaybackPowerSource.battery);
    expect(provider.audioEngineMode, AudioEngineMode.hybrid);
    expect(provider.hybridHandoffMode, HybridHandoffMode.none);
    expect(provider.hybridBackgroundMode, HybridBackgroundMode.video);
    expect(provider.allowHiddenWebAudio, isFalse);
    expect(provider.preventSleep, isFalse);
    expect(provider.webPrefetchSeconds, 30);
    expect(prefs.getString('web_playback_power_profile'), 'batterySaver');
  });

  test('charging gapless profile applies immediate hybrid gapless settings', () async {
    SharedPreferences.setMockInitialValues({'first_run_check_done': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs);

    provider.setWebPlaybackPowerProfile(WebPlaybackPowerProfile.chargingGapless);

    expect(provider.webPlaybackPowerProfile, WebPlaybackPowerProfile.chargingGapless);
    expect(provider.resolvedWebPlaybackPowerSource, ResolvedWebPlaybackPowerSource.charging);
    expect(provider.audioEngineMode, AudioEngineMode.hybrid);
    expect(provider.hybridHandoffMode, HybridHandoffMode.immediate);
    expect(provider.hybridBackgroundMode, HybridBackgroundMode.video);
    expect(provider.allowHiddenWebAudio, isTrue);
    expect(provider.preventSleep, isTrue);
    expect(provider.webPrefetchSeconds, 60);
  });

  test('manual advanced engine changes switch profile to custom', () async {
    SharedPreferences.setMockInitialValues({'first_run_check_done': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs);

    provider.setWebPlaybackPowerProfile(WebPlaybackPowerProfile.chargingGapless);
    provider.setHybridHandoffMode(HybridHandoffMode.boundary);

    expect(provider.webPlaybackPowerProfile, WebPlaybackPowerProfile.custom);
    expect(provider.hybridHandoffMode, HybridHandoffMode.boundary);
    expect(prefs.getString('web_playback_power_profile'), 'custom');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart
```

Expected: FAIL because provider profile fields and setters do not exist.

- [ ] **Step 3: Add imports and dispose cleanup**

In `packages/shakedown_core/lib/providers/settings_provider.dart`, add imports:

```dart
import 'dart:async';
import 'dart:convert';
```

Keep `dart:convert` only once. Add:

```dart
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/utils/web_power_state.dart';
```

Inside `SettingsProvider`, before the closing brace, add:

```dart
  @override
  void dispose() {
    _webChargingSubscription?.cancel();
    super.dispose();
  }
```

- [ ] **Step 4: Add fields and constants**

In `packages/shakedown_core/lib/providers/settings_provider_web.dart`, add near existing keys:

```dart
const String _webPlaybackPowerProfileKey = 'web_playback_power_profile';
```

Add to `_SettingsProviderWebFields`:

```dart
  late WebPlaybackPowerProfile _webPlaybackPowerProfile;
  late ResolvedWebPlaybackPowerSource _resolvedWebPlaybackPowerSource;
  bool? _detectedWebCharging;
  StreamSubscription<bool?>? _webChargingSubscription;
  bool _applyingWebPowerPolicy = false;
```

Add getters to `_SettingsProviderWebExtension`:

```dart
  WebPlaybackPowerProfile get webPlaybackPowerProfile =>
      _webPlaybackPowerProfile;
  ResolvedWebPlaybackPowerSource get resolvedWebPlaybackPowerSource =>
      _resolvedWebPlaybackPowerSource;
  bool? get detectedWebCharging => _detectedWebCharging;
```

- [ ] **Step 5: Add profile application methods**

In `_SettingsProviderWebExtension`, add:

```dart
  void setWebPlaybackPowerProfile(WebPlaybackPowerProfile profile) {
    _webPlaybackPowerProfile = profile;
    _prefs.setString(_webPlaybackPowerProfileKey, profile.name);
    _applyWebPlaybackPowerPolicy(persistPrefs: true);
    notifyListeners();
  }

  void _markWebPlaybackPowerProfileCustom() {
    if (_applyingWebPowerPolicy ||
        _webPlaybackPowerProfile == WebPlaybackPowerProfile.custom) {
      return;
    }
    _webPlaybackPowerProfile = WebPlaybackPowerProfile.custom;
    _resolvedWebPlaybackPowerSource = ResolvedWebPlaybackPowerSource.custom;
    _prefs.setString(
      _webPlaybackPowerProfileKey,
      WebPlaybackPowerProfile.custom.name,
    );
  }

  void _applyWebPlaybackPowerPolicy({required bool persistPrefs}) {
    final config = resolveWebPlaybackPowerPolicy(
      profile: _webPlaybackPowerProfile,
      detectedCharging: _detectedWebCharging,
    );
    _resolvedWebPlaybackPowerSource = config.resolvedSource;

    if (!config.applyEngineSettings) return;

    _applyingWebPowerPolicy = true;
    try {
      _audioEngineMode = config.audioEngineMode;
      _hybridHandoffMode = config.handoffMode;
      _hybridBackgroundMode = config.backgroundMode;
      _allowHiddenWebAudio = config.allowHiddenWebAudio;
      _webPrefetchSeconds = config.webPrefetchSeconds;
      _preventSleep = config.preventSleep;

      if (persistPrefs) {
        _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
        _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
        _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
        _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
        _prefs.setInt(_webPrefetchSecondsKey, _webPrefetchSeconds);
        _prefs.setBool(_preventSleepKey, _preventSleep);
      }
    } finally {
      _applyingWebPowerPolicy = false;
    }
  }
```

- [ ] **Step 6: Mark custom from advanced setters**

At the start of these methods in `settings_provider_web.dart`, call `_markWebPlaybackPowerProfileCustom()` before mutating the advanced field:

```dart
  void setAudioEngineMode(AudioEngineMode mode) {
    _markWebPlaybackPowerProfileCustom();
```

```dart
  void setHybridHandoffMode(HybridHandoffMode mode) {
    _markWebPlaybackPowerProfileCustom();
```

```dart
  void setAllowHiddenWebAudio(bool value) {
    _markWebPlaybackPowerProfileCustom();
```

```dart
  void setHybridBackgroundMode(HybridBackgroundMode mode) {
    _markWebPlaybackPowerProfileCustom();
```

```dart
  void setWebPrefetchSeconds(int seconds) {
    _markWebPlaybackPowerProfileCustom();
```

Do not call `_markWebPlaybackPowerProfileCustom()` inside `setHiddenSessionPreset()` because preset selection is already a high-level profile action. Instead, set:

```dart
    _webPlaybackPowerProfile = WebPlaybackPowerProfile.custom;
    _resolvedWebPlaybackPowerSource = ResolvedWebPlaybackPowerSource.custom;
    _prefs.setString(_webPlaybackPowerProfileKey, _webPlaybackPowerProfile.name);
```

inside `setHiddenSessionPreset()` before persisting the existing preset fields.

- [ ] **Step 7: Load preference and listen for web charging updates**

In `_loadWebPlaybackPreferences()` in `settings_provider_initialization.dart`, after `_applyAdaptiveWebEngineProfileIfNeeded();`, add:

```dart
    _webPlaybackPowerProfile = WebPlaybackPowerProfile.fromString(
      _prefs.getString(_webPlaybackPowerProfileKey),
    );
    _resolvedWebPlaybackPowerSource = ResolvedWebPlaybackPowerSource.battery;
    _applyWebPlaybackPowerPolicy(persistPrefs: true);
    _startWebPowerStateListener();
```

Add this method to `_SettingsProviderInitializationExtension`:

```dart
  void _startWebPowerStateListener() {
    if (!kIsWeb || _webChargingSubscription != null) return;

    getInitialWebChargingState().then((charging) {
      _handleWebChargingState(charging);
    });

    _webChargingSubscription = onWebChargingStateChanged.listen(
      _handleWebChargingState,
    );
  }

  void _handleWebChargingState(bool? charging) {
    if (_detectedWebCharging == charging) return;
    _detectedWebCharging = charging;
    if (_webPlaybackPowerProfile == WebPlaybackPowerProfile.auto) {
      _applyWebPlaybackPowerPolicy(persistPrefs: true);
      notifyListeners();
    }
  }
```

- [ ] **Step 8: Run provider tests**

Run:

```bash
flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart
```

Expected: PASS.

- [ ] **Step 9: Run existing settings tests**

Run:

```bash
flutter test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart
```

Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_web.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart
git commit -m "feat: wire web playback power profiles"
```

---

### Task 4: Make Installed PWAs Launch Hybrid By Default

**Files:**
- Modify: `apps/gdar_web/web/hybrid_init.js`
- Create: `apps/gdar_web/web/tests/pwa_strategy_regression.js`
- Modify: `apps/gdar_web/web/tests/run_tests.js`

- [ ] **Step 1: Write failing Node regression**

Create `apps/gdar_web/web/tests/pwa_strategy_regression.js`:

```javascript
const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadScript(filename) {
    const filePath = path.join(__dirname, '..', filename);
    const code = fs.readFileSync(filePath, 'utf8');
    eval(code);
}

function assert(condition, message) {
    if (!condition) {
        console.error('FAILED:', message);
        process.exit(1);
    }
    console.log('PASSED:', message);
}

global._hybridAudio = { engineType: 'hybrid', init: () => { } };
global._html5Audio = { engineType: 'html5', init: () => { } };
global._passiveAudio = { engineType: 'passive', init: () => { } };
global._gdarAudio = { engineType: 'webAudio', init: () => { } };
global._gdarScheduler = { start: () => { } };

global.localStorage = {
    getItem: () => null,
    setItem: () => { },
};

Object.defineProperty(global.navigator, 'userAgent', {
    value: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36',
    configurable: true,
});
Object.defineProperty(global.navigator, 'maxTouchPoints', {
    value: 5,
    configurable: true,
});
Object.defineProperty(global.navigator, 'hardwareConcurrency', {
    value: 8,
    configurable: true,
});
Object.defineProperty(global.window, 'innerWidth', {
    value: 430,
    configurable: true,
});
Object.defineProperty(global.window, 'devicePixelRatio', {
    value: 3,
    configurable: true,
});

global.window.matchMedia = (query) => ({
    matches: query.includes('display-mode: standalone'),
    addListener: () => { },
    removeListener: () => { },
});

loadScript('hybrid_init.js');

assert(
    global._shakedownAudioStrategy === 'hybrid',
    'Installed Android PWA without stored override should launch Hybrid',
);
assert(
    global._gdarAudio.engineType === 'hybrid',
    'window._gdarAudio should point to Hybrid for installed Android PWA',
);
```

- [ ] **Step 2: Add the regression to the JS test runner**

In `apps/gdar_web/web/tests/run_tests.js`, add this line near the other `runStandalone(...)` calls:

```javascript
runStandalone('pwa_strategy_regression.js');
```

- [ ] **Step 3: Run test to verify it fails**

Run:

```bash
node apps/gdar_web/web/tests/pwa_strategy_regression.js
```

Expected: FAIL because `hybrid_init.js` currently chooses `html5` for mobile/PWA without an override.

- [ ] **Step 4: Update strategy detection**

In `apps/gdar_web/web/hybrid_init.js`, after `const isChromebook = /CrOS/i.test(ua);`, add:

```javascript
    const isStandalonePwa =
        window.matchMedia &&
        window.matchMedia('(display-mode: standalone)').matches;
    const lowPowerDpr = window.devicePixelRatio || 1;
    const lowPowerCores = navigator.hardwareConcurrency || 0;
    const lowPowerCoreMatch =
        lowPowerCores > 0 &&
        (lowPowerCores <= 2 || (lowPowerCores <= 4 && lowPowerDpr < 2.0));
    const isLowPowerMobile = (isMobiUA || isIPadOS) && lowPowerCoreMatch;
```

Replace the mobile branch:

```javascript
    } else if (isMobiUA || isIPadOS || (hasTouch && isNarrow)) {
        // Mobile/PWA "Fresh Start" should always be HTML5
        strategy = 'html5';
        reason = `Mobile/Tablet/PWA environment detected -> HTML5 streaming engine (Fresh Start).`;
    }
```

with:

```javascript
    } else if (isStandalonePwa && !isLowPowerMobile) {
        strategy = 'hybrid';
        reason = 'Installed PWA detected -> Hybrid engine for power-aware runtime profiles.';
    } else if (isMobiUA || isIPadOS || (hasTouch && isNarrow)) {
        strategy = 'html5';
        reason = 'Mobile browser tab or low-power PWA detected -> HTML5 streaming engine.';
    }
```

At the bottom of `hybrid_init.js`, replace the repeated low-power calculation:

```javascript
    const _lpDpr = window.devicePixelRatio || 1;
    const _lpCores = navigator.hardwareConcurrency || 0;
    const _lpIsLowCores = _lpCores > 0 && (_lpCores <= 2 || (_lpCores <= 4 && _lpDpr < 2.0));
    window._gdarDetectedAsLowPower = (isMobiUA || isIPadOS) && _lpIsLowCores;
```

with:

```javascript
    window._gdarDetectedAsLowPower = isLowPowerMobile;
```

- [ ] **Step 5: Run JS regression**

Run:

```bash
node apps/gdar_web/web/tests/pwa_strategy_regression.js
```

Expected: PASS.

- [ ] **Step 6: Run JS suite**

Run:

```bash
node apps/gdar_web/web/tests/run_tests.js
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add apps/gdar_web/web/hybrid_init.js apps/gdar_web/web/tests/pwa_strategy_regression.js apps/gdar_web/web/tests/run_tests.js
git commit -m "fix: launch installed pwa with hybrid audio strategy"
```

---

### Task 5: Add Settings UI For Power Profiles

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`
- Test: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`

- [ ] **Step 1: Add failing widget assertions**

In `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`, add a web-specific test near existing playback/settings tests:

```dart
testWidgets('web playback settings expose power playback profile labels', (
  tester,
) async {
  await pumpSettingsScreen(tester);

  expect(find.text('Power Playback'), findsOneWidget);
  expect(find.text('Auto'), findsOneWidget);
  expect(find.text('Battery'), findsOneWidget);
  expect(find.text('Charging'), findsOneWidget);
});
```

If the local helper name is different, use the existing settings-screen pump helper already present in that file. The test must assert visible labels, not implementation types.

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart --plain-name "web playback settings expose power playback profile labels"
```

Expected: FAIL because those labels are not present.

- [ ] **Step 3: Add power profile selector**

In `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`, after the "Engine changes apply after relaunch" text block and before the existing engine segment, add:

```dart
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Power Playback',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SegmentedWrap<WebPlaybackPowerProfile>(
                  isFruit: isFruit,
                  scaleFactor: scaleFactor,
                  segments: [
                    _Segment(
                      value: WebPlaybackPowerProfile.auto,
                      label: 'Auto',
                      tooltip:
                          'Use charging detection when available; battery-safe if unknown',
                      icon: isFruit ? LucideIcons.sparkles : Icons.auto_mode,
                    ),
                    _Segment(
                      value: WebPlaybackPowerProfile.batterySaver,
                      label: 'Battery',
                      tooltip:
                          'Longest sessions: HTML5-like Hybrid, video survival, no hidden Web Audio',
                      icon: isFruit
                          ? LucideIcons.battery
                          : Icons.battery_saver_rounded,
                    ),
                    _Segment(
                      value: WebPlaybackPowerProfile.chargingGapless,
                      label: 'Charging',
                      tooltip:
                          'Best gapless: immediate Web Audio handoff, video survival, wake lock',
                      icon: isFruit
                          ? LucideIcons.plugZap
                          : Icons.power_rounded,
                    ),
                    _Segment(
                      value: WebPlaybackPowerProfile.custom,
                      label: 'Custom',
                      tooltip: 'Manual engine settings are active',
                      icon: isFruit ? LucideIcons.slidersHorizontal : Icons.tune,
                    ),
                  ],
                  selectedValue: settingsProvider.webPlaybackPowerProfile,
                  onSelectionChanged: (WebPlaybackPowerProfile profile) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    settingsProvider.setWebPlaybackPowerProfile(profile);
                    showRestartMessage(
                      context,
                      profile == WebPlaybackPowerProfile.custom
                          ? 'Custom keeps your manual audio settings.'
                          : 'Power playback profile applied.',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Resolved: ${settingsProvider.resolvedWebPlaybackPowerSource.name.toUpperCase()}'
                ' • Charging: ${settingsProvider.detectedWebCharging == null ? 'unknown' : settingsProvider.detectedWebCharging! ? 'yes' : 'no'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12 * scaleFactor,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
```

- [ ] **Step 4: Run targeted widget test**

Run:

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart --plain-name "web playback settings expose power playback profile labels"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart packages/shakedown_core/test/ui/screens/settings_screen_test.dart
git commit -m "feat: add pwa power playback settings"
```

---

### Task 6: Add Heartbeat Failure Diagnostics

**Files:**
- Modify: `apps/gdar_web/web/audio_heartbeat.js`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`
- Test: `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`

- [ ] **Step 1: Add failing JS contract test**

Append this test to `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`:

```dart
  test('heartbeat exposes blocked diagnostics', () {
    final repoRoot = _findRepoRoot();
    final script = File(
      p.join(repoRoot, 'apps', 'gdar_web', 'web', 'audio_heartbeat.js'),
    ).readAsStringSync();

    expect(script, contains('getBlockedDiagnostics'));
    expect(script, contains('lastReason'));
    expect(script, contains('blockedCount'));
  });
```

- [ ] **Step 2: Run contract test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart --plain-name "heartbeat exposes blocked diagnostics"
```

Expected: FAIL because `getBlockedDiagnostics` does not exist.

- [ ] **Step 3: Add JS diagnostics getter**

In `apps/gdar_web/web/audio_heartbeat.js`, add this state near `_heartbeatBlockedCount`:

```javascript
    let _lastBlockedReason = '';
```

In `_dispatchBlocked`, after incrementing count, add:

```javascript
        _lastBlockedReason = reason || '';
```

In the public `api`, replace:

```javascript
        blockedCount: function () {
            return _heartbeatBlockedCount;
        }
```

with:

```javascript
        blockedCount: function () {
            return _heartbeatBlockedCount;
        },

        getBlockedDiagnostics: function () {
            return {
                blockedCount: _heartbeatBlockedCount,
                lastReason: _lastBlockedReason,
            };
        }
```

- [ ] **Step 4: Add Dart interop fields**

In `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`, add JS interop types:

```dart
@JS('_gdarHeartbeat')
external _GdarHeartbeat? get _heartbeat;

@JS()
@anonymous
extension type _GdarHeartbeat(JSObject _) {
  external _HeartbeatBlockedDiagnostics getBlockedDiagnostics();
}

@JS()
@anonymous
extension type _HeartbeatBlockedDiagnostics(JSObject _) {
  external JSNumber? get blockedCount;
  external JSString? get lastReason;
}
```

Add accessors to `_GaplessPlayerBase`:

```dart
  int get heartbeatBlockedCount {
    try {
      return _heartbeat?.getBlockedDiagnostics().blockedCount?.toDartInt ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String get heartbeatLastBlockedReason {
    try {
      return _heartbeat?.getBlockedDiagnostics().lastReason?.toDart ?? '';
    } catch (_) {
      return '';
    }
  }
```

- [ ] **Step 5: Surface in diagnostics provider**

In `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`, add the heartbeat blocked count and resolved power source to the HUD snapshot fields already assembled there:

```dart
      heartbeatBlockedCount: _audioPlayer.heartbeatBlockedCount,
      heartbeatLastBlockedReason: _audioPlayer.heartbeatLastBlockedReason,
      webPlaybackPowerSource: settings.resolvedWebPlaybackPowerSource.name,
```

If `HudSnapshot` is a concrete class in the same diagnostics path, add:

```dart
  final int heartbeatBlockedCount;
  final String heartbeatLastBlockedReason;
  final String webPlaybackPowerSource;
```

with constructor defaults:

```dart
    this.heartbeatBlockedCount = 0,
    this.heartbeatLastBlockedReason = '',
    this.webPlaybackPowerSource = 'battery',
```

- [ ] **Step 6: Run contract test**

Run:

```bash
flutter test packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart --plain-name "heartbeat exposes blocked diagnostics"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add apps/gdar_web/web/audio_heartbeat.js packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
git commit -m "feat: expose pwa heartbeat diagnostics"
```

---

### Task 7: Update Documentation

**Files:**
- Modify: `docs/WEB_PLAYBACK_DECISION_TREE.md`
- Modify: `apps/gdar_web/docs/first_run_presets.md`
- Modify: `apps/gdar_web/docs/web_pwa_audio_survival_analysis.md`

- [ ] **Step 1: Update decision tree**

In `docs/WEB_PLAYBACK_DECISION_TREE.md`, replace the PWA row with:

```markdown
| **[P]** | **PWA** | Power Profile: Auto | Battery: Off + Video; Charging: Immediate + Video | Battery: HTML5-like Hybrid; Charging: WA gapless | Installed PWA launches Hybrid so runtime power profiles can switch between long-session and gapless behavior without engine relaunch. |
```

Replace the Compatible section with:

```markdown
### Battery Saver / Compatible
- **UI Power Mode**: Battery
- **UI Background Mode**: Compatible
- **UI Handoff Mode**: Off
- **UI Survival Strategy**: Video
- **HUD STB Chip**: `STB:STB`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:NONE`
- **Description**: Designed for battery or unreliable mobile browsers. Hybrid remains selected, but Web Audio handoff is disabled so playback behaves like durable HTML5 with video survival.
```

Add a Charging section:

```markdown
### Charging Gapless
- **UI Power Mode**: Charging
- **UI Background Mode**: Gapless
- **UI Handoff Mode**: Immediate
- **UI Survival Strategy**: Video
- **HUD STB Chip**: `STB:MAX`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:IMM`
- **Description**: Designed for plugged-in Android/iOS PWA sessions where true gapless playback is preferred over battery conservation. Starts on HTML5, then immediately hands off to Web Audio and keeps video survival active for hidden sessions.
```

- [ ] **Step 2: Update first-run presets**

In `apps/gdar_web/docs/first_run_presets.md`, update the `HiddenSessionPreset` table so `stability` uses `video` and `maxGapless` uses `immediate + video`. Add a `WebPlaybackPowerProfile` section with the policy table from this plan.

- [ ] **Step 3: Update survival analysis**

In `apps/gdar_web/docs/web_pwa_audio_survival_analysis.md`, replace percentage claims with qualitative rankings:

```markdown
| Rank | Config | Reason |
| :--- | :--- | :--- |
| 1 | `hybrid + chargingGapless + video` | Best gapless behavior while charging; still has HTML5 fallback and video survival. |
| 2 | `hybrid + batterySaver + video` | Best battery-session durability; disables Web Audio handoff and keeps the browser in media-playback mode. |
| 3 | `hybrid + heartbeat` | Lower overhead than video, but less reliable on mobile background sessions. |
| 4 | `webAudio + no survival` | Best precision while visible; weakest hidden-session survival on mobile. |
```

- [ ] **Step 4: Commit**

```bash
git add docs/WEB_PLAYBACK_DECISION_TREE.md apps/gdar_web/docs/first_run_presets.md apps/gdar_web/docs/web_pwa_audio_survival_analysis.md
git commit -m "docs: document pwa power playback profiles"
```

---

### Task 8: Verification

**Files:**
- No code edits.

- [ ] **Step 1: Run Dart formatting**

Run:

```bash
dart format packages/shakedown_core/lib packages/shakedown_core/test
```

Expected: command exits 0.

- [ ] **Step 2: Run focused Flutter tests**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_playback_power_policy_test.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run JS engine tests**

Run:

```bash
node apps/gdar_web/web/tests/run_tests.js
```

Expected: PASS.

- [ ] **Step 4: Run package analysis**

Run:

```bash
flutter analyze packages/shakedown_core apps/gdar_web
```

Expected: no errors.

- [ ] **Step 5: Run monorepo validation subset**

Run:

```bash
dart run melos run test
```

Expected: command exits 0. If unrelated existing failures appear, capture the failing test names and error messages before stopping.

- [ ] **Step 6: Manual PWA validation on Android and iOS**

Android Chrome PWA:

```text
1. Install/open the PWA.
2. Open Settings > Playback > Power Playback.
3. Select Battery.
4. Start a show, lock the screen for 20 minutes, unlock.
5. Confirm playback continued and HUD shows HYB/H5-like behavior, HF:NONE, BG:VID.
6. Select Charging while plugged in.
7. Start a show with adjacent continuous tracks, lock the screen for 20 minutes, unlock.
8. Confirm playback continued and HUD shows HF:IMM, BG:VID, and Last Gap remains near 0ms at track boundaries.
```

iOS Safari PWA:

```text
1. Install/open the PWA from Home Screen.
2. Repeat the Android Battery sequence.
3. Repeat the Android Charging sequence.
4. Record whether Battery Status API reports unknown; Auto should resolve to Battery when unknown.
5. Record whether heartbeat blocked diagnostics remain at 0.
```

- [ ] **Step 7: Commit verification notes**

Create `reports/YYYY-MM-DD_pwa_power_playback_profiles.md` with:

```markdown
# PWA Power Playback Profiles Verification

## Automated
- dart format:
- focused flutter tests:
- node web audio tests:
- flutter analyze:
- melos test:

## Android PWA
- Device:
- Browser:
- Battery profile result:
- Charging profile result:
- HUD notes:

## iOS PWA
- Device:
- Browser:
- Battery profile result:
- Charging profile result:
- HUD notes:
```

Commit:

```bash
git add reports/YYYY-MM-DD_pwa_power_playback_profiles.md
git commit -m "test: record pwa power playback verification"
```

---

## Self-Review

Spec coverage:

- Android/iOS PWA support: covered by Hybrid PWA launch change, Battery API fallback, and manual validation.
- Charging prioritizes true gapless: covered by `chargingGapless` profile using Hybrid, immediate handoff, hidden WA allowed, video survival, and 60s prefetch.
- Battery prioritizes long playback survival: covered by `batterySaver` profile using Hybrid with handoff disabled, video survival, hidden WA disabled, no wake lock, and 30s prefetch.
- Browser API instability: covered by unknown charging fallback to battery-safe behavior.
- Existing user control: covered by `custom` profile when advanced audio settings are changed.
- Diagnostics: covered by heartbeat blocked diagnostics and HUD power source fields.

Placeholder scan:

- No unresolved placeholder markers or open-ended implementation steps remain.
- Every code-editing task includes exact files and code snippets.
- Every test task includes a command and expected outcome.

Type consistency:

- `WebPlaybackPowerProfile`, `ResolvedWebPlaybackPowerSource`, and `WebPlaybackPowerPolicyConfig` names are consistent across tasks.
- Existing enum values match current code: `AudioEngineMode.hybrid`, `HybridHandoffMode.none`, `HybridHandoffMode.immediate`, `HybridBackgroundMode.video`.
- Preference key `web_playback_power_profile` is consistent in provider tests and provider code.
