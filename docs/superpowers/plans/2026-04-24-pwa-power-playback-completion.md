# PWA Power Playback Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Model routing:** Use `gpt-5.4-mini` for Tasks 1, 2, 4, and 5. Use `gpt-5.4` with medium reasoning for Task 3 because it touches web JS diagnostics, Dart web interop, HUD contracts, and playback diagnostics surfaces. Task 6 is final controller verification and should be run by the main agent. Do not hand the entire plan to one mini agent; execute one task per worker and review between tasks.
>
> **Current branch/worktree:** `/home/jam/StudioProjects/gdar/.worktrees/pwa-power-playback-profiles` on `feature/pwa-power-playback-profiles`.
>
> **Known environment constraint:** Use `/home/jam/.config/nvm/versions/node/v24.14.0/bin/node` for JS tests; plain `node` is not on this shell's `PATH`. Git commits may fail while `.git` metadata is read-only; if a commit fails, preserve a patch bundle under `/tmp` and continue only after confirming `git diff` still contains the intended changes.

**Goal:** Complete the remaining PWA power playback work so Android/iOS installed PWAs can choose between battery-safe long sessions and charging gapless sessions, with settings UI, diagnostics, docs, and verification notes.

**Architecture:** Keep installed PWA launch on Hybrid, then let the Dart settings policy drive Hybrid's handoff/background/prefetch/wakelock knobs. Battery mode disables Web Audio handoff and hidden Web Audio while keeping video survival. Charging mode enables immediate Web Audio handoff and wake lock while keeping video survival. Diagnostics should expose whether browser survival helpers are being blocked so long-session failures can be investigated instead of guessed.

**Tech Stack:** Flutter/Dart Provider, SharedPreferences, Dart JS interop, `web` package, Fruit settings UI, web JS audio engines, Flutter tests, Node regression tests.

---

## Current Completed Work

- Done: Task 1 pure power policy.
- Done: Task 2 web charging detection bridge.
- Done: Task 3 settings provider power profile wiring.
- Merged but not Node-verified in this shell: Task 4 installed PWA Hybrid default.
- Remaining: Task 4 review/verification, Task 5 settings UI, Task 6 heartbeat failure diagnostics, Task 7 docs, Task 8 final verification/report.

## File Structure

- Modify: `apps/gdar_web/web/hybrid_init.js`
  - Review current Task 4 logic. Keep installed non-low-power PWA on Hybrid; keep low-power/mobile browser tab on HTML5.
- Modify: `apps/gdar_web/web/tests/run_tests.js`
  - Keep `pwa_strategy_regression.js` in the standalone runner.
- Create/modify: `apps/gdar_web/web/tests/pwa_strategy_regression.js`
  - Regression for installed Android PWA defaulting to Hybrid.
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart`
  - Import power policy enum for the part file.
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`
  - Add Fruit-compatible Power Playback segmented selector and resolved-state text.
- Modify: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
  - Add widget test for the new visible labels.
- Modify: `apps/gdar_web/web/audio_heartbeat.js`
  - Track heartbeat blocked count and last blocked reason in a stable getter.
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
  - Add JS interop for heartbeat blocked diagnostics.
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart`
  - Expose safe Dart getters for heartbeat blocked diagnostics.
- Modify: `packages/shakedown_core/lib/models/dng_snapshot.dart`
  - Add telemetry fields for heartbeat blocked diagnostics.
- Modify: `packages/shakedown_core/lib/models/hud_snapshot.dart`
  - Add HUD fields/map chips for power source and heartbeat blocked diagnostics.
- Modify: `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`
  - Populate DNG/HUD diagnostics from settings and player state.
- Modify: `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`
  - Add static contract test for JS heartbeat diagnostics.
- Modify: `docs/WEB_PLAYBACK_DECISION_TREE.md`
  - Reconcile decision tree with battery/charging profiles.
- Modify: `apps/gdar_web/docs/first_run_presets.md`
  - Document first-run policy and power profile mapping.
- Modify: `apps/gdar_web/docs/web_pwa_audio_survival_analysis.md`
  - Replace over-specific survival claims with qualitative ranking.
- Create: `reports/2026-04-24_pwa_power_playback_profiles.md`
  - Final automated/manual verification record.

---

### Task 1: Review And Verify Installed PWA Hybrid Launch

**Model:** `gpt-5.4-mini`

**Files:**
- Modify only if review finds a real defect: `apps/gdar_web/web/hybrid_init.js`
- Modify only if missing: `apps/gdar_web/web/tests/run_tests.js`
- Modify only if missing: `apps/gdar_web/web/tests/pwa_strategy_regression.js`

- [ ] **Step 1: Confirm the regression file exists**

Run:

```bash
test -f apps/gdar_web/web/tests/pwa_strategy_regression.js
sed -n '1,220p' apps/gdar_web/web/tests/pwa_strategy_regression.js
```

Expected: file exists and asserts both:

```javascript
global._shakedownAudioStrategy === 'hybrid'
global._gdarAudio.engineType === 'hybrid'
```

- [ ] **Step 2: Confirm the test runner includes the regression**

Run:

```bash
rg -n "pwa_strategy_regression" apps/gdar_web/web/tests/run_tests.js
```

Expected output includes:

```javascript
runStandalone('pwa_strategy_regression.js');
```

- [ ] **Step 3: Review the installed PWA strategy branch**

In `apps/gdar_web/web/hybrid_init.js`, confirm the strategy branch keeps this behavior:

```javascript
    } else if (isChromebook) {
        strategy = 'webAudio';
        reason = `Chromebook detected (CrOS) -> Web Audio API enabled.`;
    } else if (isStandalonePwa) {
        if (isLowPowerMobile) {
            strategy = 'html5';
            reason = 'Installed low-power PWA detected -> HTML5 streaming engine.';
        } else {
            strategy = 'hybrid';
            reason = 'Installed PWA detected -> Hybrid orchestrator.';
        }
    } else if (isMobileLike) {
        strategy = 'html5';
        reason = `Mobile/Tablet browser tab detected -> HTML5 streaming engine.`;
    }
```

- [ ] **Step 4: Run JS regression when Node is available**

Run:

```bash
/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/pwa_strategy_regression.js
```

Expected: PASS with both installed-PWA assertions.

- [ ] **Step 5: Run JS suite when Node is available**

Run:

```bash
/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/run_tests.js
```

Expected: PASS.

- [ ] **Step 6: Commit or preserve patch**

Run:

```bash
git add apps/gdar_web/web/hybrid_init.js apps/gdar_web/web/tests/run_tests.js apps/gdar_web/web/tests/pwa_strategy_regression.js
git commit -m "fix: launch installed pwa with hybrid audio strategy"
```

If commit fails because `.git` metadata is read-only, run:

```bash
stamp=$(date -u +%Y%m%d_%H%M%S)
mkdir -p "/tmp/gdar_pwa_power_completion_$stamp"
git diff -- apps/gdar_web/web/hybrid_init.js apps/gdar_web/web/tests/run_tests.js > "/tmp/gdar_pwa_power_completion_$stamp/task1-tracked.diff"
tar -czf "/tmp/gdar_pwa_power_completion_$stamp/task1-untracked.tgz" apps/gdar_web/web/tests/pwa_strategy_regression.js
printf '%s\n' "/tmp/gdar_pwa_power_completion_$stamp" > /tmp/gdar_pwa_power_completion_latest
```

Expected: tracked diff and untracked tarball exist under `/tmp/gdar_pwa_power_completion_<stamp>`.

---

### Task 2: Add Settings UI For Power Playback Profiles

**Model:** `gpt-5.4-mini`

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`
- Test: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`

- [ ] **Step 1: Write the failing visible-label widget test**

Append this test inside `main()` in `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`:

```dart
testWidgets('web playback settings expose power playback profile labels', (
  WidgetTester tester,
) async {
  final settingsProvider = SettingsProvider(prefs);

  await tester.pumpWidget(createTestableWidget(settingsProvider));
  await tester.pump(const Duration(seconds: 1));

  final playbackTitle = find.text('Playback');
  expect(playbackTitle, findsOneWidget);

  if (find.text('Web Audio Engine').evaluate().isEmpty) {
    await tester.tap(playbackTitle);
    await tester.pump(const Duration(milliseconds: 500));
  }

  await tester.scrollUntilVisible(
    find.text('Web Audio Engine'),
    300,
    scrollable: find.byType(Scrollable),
  );
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.text('Power Playback'), findsOneWidget);
  expect(find.text('Auto'), findsOneWidget);
  expect(find.text('Battery'), findsOneWidget);
  expect(find.text('Charging'), findsOneWidget);
  expect(find.text('Custom'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails before UI code**

Run:

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart --plain-name "web playback settings expose power playback profile labels"
```

Expected: FAIL because `Power Playback` is not present.

- [ ] **Step 3: Add the power policy import**

In `packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart`, add:

```dart
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
```

- [ ] **Step 4: Add the selector after the relaunch text block**

In `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`, insert this immediately after the `Engine changes apply after relaunch (or browser refresh).` text block and before the existing engine `_SegmentedWrap<AudioEngineMode>`:

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
                          'Best gapless while plugged in: immediate Web Audio handoff and video survival',
                      icon: isFruit ? LucideIcons.plugZap : Icons.power_rounded,
                    ),
                    _Segment(
                      value: WebPlaybackPowerProfile.custom,
                      label: 'Custom',
                      tooltip: 'Manual advanced engine settings are active',
                      icon: isFruit
                          ? LucideIcons.slidersHorizontal
                          : Icons.tune,
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

- [ ] **Step 5: Run targeted widget test**

Run:

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart --plain-name "web playback settings expose power playback profile labels"
```

Expected: PASS.

- [ ] **Step 6: Run focused formatting and analysis**

Run:

```bash
dart format packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart packages/shakedown_core/test/ui/screens/settings_screen_test.dart
flutter analyze packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart packages/shakedown_core/test/ui/screens/settings_screen_test.dart
```

Expected: formatter exits 0; analyzer reports no issues for these files.

- [ ] **Step 7: Commit or preserve patch**

Run:

```bash
git add packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart packages/shakedown_core/test/ui/screens/settings_screen_test.dart
git commit -m "feat: add pwa power playback settings"
```

If commit fails because `.git` metadata is read-only, run:

```bash
stamp=$(date -u +%Y%m%d_%H%M%S)
mkdir -p "/tmp/gdar_pwa_power_completion_$stamp"
git diff -- packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart packages/shakedown_core/test/ui/screens/settings_screen_test.dart > "/tmp/gdar_pwa_power_completion_$stamp/task2.diff"
printf '%s\n' "/tmp/gdar_pwa_power_completion_$stamp" > /tmp/gdar_pwa_power_completion_latest
```

Expected: diff exists under `/tmp/gdar_pwa_power_completion_<stamp>/task2.diff`.

---

### Task 3: Add Heartbeat Failure Diagnostics

**Model:** `gpt-5.4` with medium reasoning

**Files:**
- Modify: `apps/gdar_web/web/audio_heartbeat.js`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart`
- Modify: `packages/shakedown_core/lib/models/dng_snapshot.dart`
- Modify: `packages/shakedown_core/lib/models/hud_snapshot.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`
- Test: `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`

- [ ] **Step 1: Add failing static contract test**

Append this test inside `main()` in `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart`:

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

In `apps/gdar_web/web/audio_heartbeat.js`, after:

```javascript
    let _heartbeatBlockedCount = 0;
```

add:

```javascript
    let _lastBlockedReason = '';
```

Inside `_dispatchBlocked(type, reason)`, immediately after `_heartbeatBlockedCount++;`, add:

```javascript
        _lastBlockedReason = reason || '';
```

In the public `api`, replace the final `blockedCount` method with:

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

- [ ] **Step 4: Add Dart JS interop types**

In `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`, after the existing `_reasonVal` external, add:

```dart
@JS('_gdarHeartbeat')
external _GdarHeartbeat? get _heartbeat;
```

After `_GdarAudioEngine`, add:

```dart
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

- [ ] **Step 5: Add safe Dart accessors**

In `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart`, after `bool get heartbeatNeeded`, add:

```dart
  int get heartbeatBlockedCount {
    if (!_useJsEngine) return 0;
    try {
      return _heartbeat?.getBlockedDiagnostics().blockedCount?.toDartInt ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String get heartbeatLastBlockedReason {
    if (!_useJsEngine) return '';
    try {
      return _heartbeat?.getBlockedDiagnostics().lastReason?.toDart ?? '';
    } catch (_) {
      return '';
    }
  }
```

- [ ] **Step 6: Add DNG telemetry fields**

In `packages/shakedown_core/lib/models/dng_snapshot.dart`, add fields after `final bool hbNeeded;`:

```dart
  final int heartbeatBlockedCount;
  final String heartbeatLastBlockedReason;
```

Add constructor parameters after `required this.hbNeeded,`:

```dart
    this.heartbeatBlockedCount = 0,
    this.heartbeatLastBlockedReason = '',
```

- [ ] **Step 7: Add HUD fields and chips**

In `packages/shakedown_core/lib/models/hud_snapshot.dart`, add fields after `final String heartbeat; // HB`:

```dart
  final String heartbeatBlocked; // HBB
  final String powerSource; // PWR
```

Add required constructor parameters after `required this.heartbeat,`:

```dart
    required this.heartbeatBlocked,
    required this.powerSource,
```

Add empty defaults after `heartbeat: '--',`:

```dart
    heartbeatBlocked: '--',
    powerSource: '--',
```

Add map entries after `'HB': heartbeat,`:

```dart
      'HBB': heartbeatBlocked,
      'PWR': powerSource,
```

Add `copyWith` parameters after `String? heartbeat,`:

```dart
    String? heartbeatBlocked,
    String? powerSource,
```

Pass them into the copied `HudSnapshot` after `heartbeat: heartbeat ?? this.heartbeat,`:

```dart
      heartbeatBlocked: heartbeatBlocked ?? this.heartbeatBlocked,
      powerSource: powerSource ?? this.powerSource,
```

- [ ] **Step 8: Populate diagnostics provider**

In `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`, add to `DngSnapshot(...)` after `hbNeeded: _audioPlayer.heartbeatNeeded,`:

```dart
      heartbeatBlockedCount: _audioPlayer.heartbeatBlockedCount,
      heartbeatLastBlockedReason: _audioPlayer.heartbeatLastBlockedReason,
```

In `HudSnapshot(...)`, add after `heartbeat: dng.hbActive ? 'ON' : (dng.hbNeeded ? 'ND' : 'OFF'),`:

```dart
      heartbeatBlocked: dng.heartbeatBlockedCount > 0
          ? dng.heartbeatBlockedCount.toString()
          : '--',
      powerSource: _shortPowerSource(settings.resolvedWebPlaybackPowerSource),
```

Add this helper before `_shortMode`:

```dart
  String _shortPowerSource(ResolvedWebPlaybackPowerSource source) {
    switch (source) {
      case ResolvedWebPlaybackPowerSource.battery:
        return 'BAT';
      case ResolvedWebPlaybackPowerSource.charging:
        return 'CHG';
      case ResolvedWebPlaybackPowerSource.custom:
        return 'CUS';
    }
  }
```

If `ResolvedWebPlaybackPowerSource` is not in scope through `settings_provider.dart`, add this import to `packages/shakedown_core/lib/providers/audio_provider.dart`:

```dart
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
```

- [ ] **Step 9: Run focused tests and analyzer**

Run:

```bash
flutter test packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart --plain-name "heartbeat exposes blocked diagnostics"
dart format apps/gdar_web/web/audio_heartbeat.js packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart packages/shakedown_core/lib/models/dng_snapshot.dart packages/shakedown_core/lib/models/hud_snapshot.dart packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
flutter analyze packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart packages/shakedown_core/lib/models/dng_snapshot.dart packages/shakedown_core/lib/models/hud_snapshot.dart packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
```

Expected: test passes; format exits 0; analyzer reports no issues.

- [ ] **Step 10: Commit or preserve patch**

Run:

```bash
git add apps/gdar_web/web/audio_heartbeat.js packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart packages/shakedown_core/lib/models/dng_snapshot.dart packages/shakedown_core/lib/models/hud_snapshot.dart packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
git commit -m "feat: expose pwa heartbeat diagnostics"
```

If commit fails because `.git` metadata is read-only, run:

```bash
stamp=$(date -u +%Y%m%d_%H%M%S)
mkdir -p "/tmp/gdar_pwa_power_completion_$stamp"
git diff -- apps/gdar_web/web/audio_heartbeat.js packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart packages/shakedown_core/lib/models/dng_snapshot.dart packages/shakedown_core/lib/models/hud_snapshot.dart packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart > "/tmp/gdar_pwa_power_completion_$stamp/task3.diff"
printf '%s\n' "/tmp/gdar_pwa_power_completion_$stamp" > /tmp/gdar_pwa_power_completion_latest
```

Expected: diff exists under `/tmp/gdar_pwa_power_completion_<stamp>/task3.diff`.

---

### Task 4: Update Documentation

**Model:** `gpt-5.4-mini`

**Files:**
- Modify: `docs/WEB_PLAYBACK_DECISION_TREE.md`
- Modify: `apps/gdar_web/docs/first_run_presets.md`
- Modify: `apps/gdar_web/docs/web_pwa_audio_survival_analysis.md`

- [ ] **Step 1: Update decision tree PWA row**

In `docs/WEB_PLAYBACK_DECISION_TREE.md`, replace the PWA row with:

```markdown
| **[P]** | **PWA** | Power Profile: Auto | Battery: Off + Video; Charging: Immediate + Video | Battery: HTML5-like Hybrid; Charging: WA gapless | Installed PWA launches Hybrid so runtime power profiles can switch between long-session and gapless behavior without engine relaunch. |
```

- [ ] **Step 2: Replace Compatible section wording**

In `docs/WEB_PLAYBACK_DECISION_TREE.md`, replace the Compatible section with:

```markdown
### Battery Saver / Compatible
- **UI Power Mode**: Battery
- **UI Background Mode**: Compatible
- **UI Handoff Mode**: Off
- **UI Survival Strategy**: Video
- **HUD STB Chip**: `STB:STB`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:NONE`
- **HUD PWR Chip**: `PWR:BAT`
- **Description**: Designed for battery or unreliable mobile browsers. Hybrid remains selected, but Web Audio handoff is disabled so playback behaves like durable HTML5 with video survival.
```

- [ ] **Step 3: Add Charging Gapless section**

In `docs/WEB_PLAYBACK_DECISION_TREE.md`, add after the Battery Saver / Compatible section:

```markdown
### Charging Gapless
- **UI Power Mode**: Charging
- **UI Background Mode**: Gapless
- **UI Handoff Mode**: Immediate
- **UI Survival Strategy**: Video
- **HUD STB Chip**: `STB:MAX`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:IMM`
- **HUD PWR Chip**: `PWR:CHG`
- **Description**: Designed for plugged-in Android/iOS PWA sessions where true gapless playback is preferred over battery conservation. Starts on HTML5, then immediately hands off to Web Audio and keeps video survival active for hidden sessions.
```

- [ ] **Step 4: Add power profile policy to first-run docs**

In `apps/gdar_web/docs/first_run_presets.md`, add this section:

```markdown
## Web Playback Power Profiles

Installed Android/iOS PWAs launch Hybrid by default. The power profile then controls Hybrid runtime settings.

| User Profile | Resolved Source | Engine | Handoff | Background | Hidden Web Audio | Prevent Sleep | Prefetch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `auto` + charging detected | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60s` |
| `auto` + battery detected | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `auto` + unknown charging | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `batterySaver` | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `chargingGapless` | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60s` |
| `custom` | `custom` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |
```

- [ ] **Step 5: Update survival analysis ranking**

In `apps/gdar_web/docs/web_pwa_audio_survival_analysis.md`, replace percentage claims for PWA survival with this qualitative ranking:

```markdown
| Rank | Config | Reason |
| :--- | :--- | :--- |
| 1 | `hybrid + chargingGapless + video` | Best gapless behavior while charging; still has HTML5 fallback and video survival. |
| 2 | `hybrid + batterySaver + video` | Best battery-session durability; disables Web Audio handoff and keeps the browser in media-playback mode. |
| 3 | `hybrid + heartbeat` | Lower overhead than video, but less reliable on mobile background sessions. |
| 4 | `webAudio + no survival` | Best precision while visible; weakest hidden-session survival on mobile. |
```

- [ ] **Step 6: Run doc consistency checks**

Run:

```bash
rg -n "Power Profile|batterySaver|chargingGapless|PWR:|HBB|video survival|Battery Status API" docs/WEB_PLAYBACK_DECISION_TREE.md apps/gdar_web/docs/first_run_presets.md apps/gdar_web/docs/web_pwa_audio_survival_analysis.md
```

Expected: matches appear in all three docs.

- [ ] **Step 7: Commit or preserve patch**

Run:

```bash
git add docs/WEB_PLAYBACK_DECISION_TREE.md apps/gdar_web/docs/first_run_presets.md apps/gdar_web/docs/web_pwa_audio_survival_analysis.md
git commit -m "docs: document pwa power playback profiles"
```

If commit fails because `.git` metadata is read-only, run:

```bash
stamp=$(date -u +%Y%m%d_%H%M%S)
mkdir -p "/tmp/gdar_pwa_power_completion_$stamp"
git diff -- docs/WEB_PLAYBACK_DECISION_TREE.md apps/gdar_web/docs/first_run_presets.md apps/gdar_web/docs/web_pwa_audio_survival_analysis.md > "/tmp/gdar_pwa_power_completion_$stamp/task4.diff"
printf '%s\n' "/tmp/gdar_pwa_power_completion_$stamp" > /tmp/gdar_pwa_power_completion_latest
```

Expected: diff exists under `/tmp/gdar_pwa_power_completion_<stamp>/task4.diff`.

---

### Task 5: Final Verification Report

**Model:** `gpt-5.4-mini`

**Files:**
- Create: `reports/2026-04-24_pwa_power_playback_profiles.md`

- [ ] **Step 1: Run formatting**

Run:

```bash
dart format packages/shakedown_core/lib packages/shakedown_core/test
```

Expected: exits 0.

- [ ] **Step 2: Run focused Flutter tests**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_playback_power_policy_test.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run settings UI test**

Run:

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart --plain-name "web playback settings expose power playback profile labels"
```

Expected: PASS.

- [ ] **Step 4: Run JS engine tests when Node is available**

Run:

```bash
/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/pwa_strategy_regression.js
/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/run_tests.js
```

Expected: PASS.

- [ ] **Step 5: Run package analysis**

Run:

```bash
flutter analyze packages/shakedown_core apps/gdar_web
```

Expected: no errors.

- [ ] **Step 6: Run monorepo test subset**

Run:

```bash
dart run melos run test
```

Expected: exits 0. If unrelated existing failures appear, capture exact failing test names and error messages in the report.

- [ ] **Step 7: Create verification report**

Create `reports/2026-04-24_pwa_power_playback_profiles.md`:

```markdown
# PWA Power Playback Profiles Verification

## Automated
- dart format: PENDING
- focused flutter tests: PENDING
- settings UI test: PENDING
- node pwa strategy test: PENDING
- node web audio suite: PENDING
- flutter analyze: PENDING
- melos test: PENDING

## Android PWA Manual
- Device: PENDING
- Browser: PENDING
- Battery profile result: PENDING
- Charging profile result: PENDING
- HUD notes: PENDING

## iOS PWA Manual
- Device: PENDING
- Browser: PENDING
- Battery profile result: PENDING
- Charging profile result: PENDING
- Battery Status API state: PENDING
- Heartbeat blocked diagnostics: PENDING

## Known Blockers
- Node runtime: PENDING
- Git commit permissions: PENDING
```

Replace each `PENDING` value with the actual command result or manual result before final commit. Do not commit the report while `PENDING` remains.

- [ ] **Step 8: Commit or preserve report patch**

Run:

```bash
git add reports/2026-04-24_pwa_power_playback_profiles.md
git commit -m "test: record pwa power playback verification"
```

If commit fails because `.git` metadata is read-only, run:

```bash
stamp=$(date -u +%Y%m%d_%H%M%S)
mkdir -p "/tmp/gdar_pwa_power_completion_$stamp"
tar -czf "/tmp/gdar_pwa_power_completion_$stamp/task5-report.tgz" reports/2026-04-24_pwa_power_playback_profiles.md
printf '%s\n' "/tmp/gdar_pwa_power_completion_$stamp" > /tmp/gdar_pwa_power_completion_latest
```

Expected: report tarball exists under `/tmp/gdar_pwa_power_completion_<stamp>/task5-report.tgz`.

---

### Task 6: Controller Review And Handoff

**Model:** main controller, not a subagent

**Files:**
- No planned code edits unless review finds a defect.

- [ ] **Step 1: Inspect final status**

Run:

```bash
git status --short --branch
git diff --stat
```

Expected: branch is `feature/pwa-power-playback-profiles`; only intended PWA power playback files are dirty if commits were blocked.

- [ ] **Step 2: Check for whitespace errors**

Run:

```bash
git diff --check
```

Expected: no output and exit 0.

- [ ] **Step 3: Check plan completion markers**

Run:

```bash
rg -n "PENDING" reports/2026-04-24_pwa_power_playback_profiles.md
```

Expected: no matches in the report before final handoff.

- [ ] **Step 4: Final handoff summary**

Report:

```text
Completed:
- Task 1: installed PWA Hybrid launch review/verification
- Task 2: settings UI
- Task 3: heartbeat diagnostics
- Task 4: docs
- Task 5: verification report

Automated verification:
- <command>: <result>

Manual verification:
- Android PWA: <result or not run>
- iOS PWA: <result or not run>

Uncommitted/patch-preserved work:
- <none or backup path>
```

---

## Self-Review

Spec coverage:
- Android/iOS installed PWA support is covered by Task 1 and manual validation in Task 5.
- Battery sessions are covered by the already-implemented policy and Task 2 UI surface.
- Charging sessions are covered by the already-implemented policy, Task 2 UI surface, and Task 4 docs.
- Long-session survivability diagnostics are covered by Task 3 heartbeat blocked diagnostics.
- Documentation is covered by Task 4.
- Verification and handoff are covered by Tasks 5 and 6.

Placeholder scan:
- No implementation step contains unresolved placeholder language.
- The only `PENDING` strings are inside the verification report template and are explicitly required to be replaced before final commit.

Type consistency:
- `WebPlaybackPowerProfile` and `ResolvedWebPlaybackPowerSource` match the implemented policy file.
- `HybridHandoffMode.none`, `HybridHandoffMode.immediate`, and `HybridBackgroundMode.video` match existing enum values.
- HUD chip keys `PWR` and `HBB` are unique and do not collide with existing `HudSnapshot.toMap()` keys.
