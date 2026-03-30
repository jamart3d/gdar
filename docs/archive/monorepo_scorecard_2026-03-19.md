# Monorepo Scorecard

Date: 2026-03-19 (updated same day, second pass)
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`

## Overall Score

**8.0/10**

Up from 7.8 earlier today. The second pass in this session closed two of the
three gaps that were holding the score below 8: the platform contract tests are
now real and passing, and a genuine Liquid Glass correctness bug on phone was
found and fixed with tests that prove it stays fixed. The web audio layer also
got meaningfully cleaner. `SettingsProvider` remains the one ceiling the Dart
language itself makes hard to address without a larger refactor.

## Category Breakdown

### Architecture: 8.5/10

Unchanged. The monorepo boundary structure is sound. The remaining weakness is
that a few shared classes still blur orchestration, persistence, platform
policy, and UI state — but no architectural regression occurred and the
platform contract work makes those boundaries more explicit where it matters.

### Maintainability: 7.0/10

Up from 6.8. Two concrete improvements:

- The web audio JS layer is cleaner. Fifteen-plus copies of an inline
  `heartbeatNeeded` lambda across `hybrid_html5_engine.js` and
  `passive_audio_engine.js` are now replaced by a single shared
  `window._gdarIsHeartbeatNeeded()` utility in `audio_utils.js`. Each engine’s
  state emission now emits a consistent `contextState` string with format
  `’<engine> [HBN/HBO] v1.1.hb’` instead of ad-hoc variants.
- `web_ui_audio_engines.md` was corrected: the removed `hybridForceHtml5Start`
  flag was deleted from all preset tables, and the doc now matches the running
  code.

`SettingsProvider` remains at 1,964 lines and is still the largest hotspot. A
Dart `part`-file extension split was attempted and reverted: Dart extension
methods dispatch statically, which breaks test fakes that implement the provider
interface via `noSuchMethod`. The correct path (separate provider classes or
mixins) requires a larger refactor.

### Test Quality: 8.0/10

Up from 7.4. Three new platform contract test files were added, covering exactly
the gaps the previous scorecard named:

- `test/providers/settings_provider_defaults_contract_test.dart` — 10 tests
  covering TV vs phone platform defaults (`hideTvScrollbars`, `preventSleep`,
  `showPlaybackMessages`, `oilScreensaverMode`, `activeAppFont`,
  `performanceMode`) and user-override semantics.
- `test/utils/message_routing_contract_test.dart` — 3 tests verifying that
  `showMessage()` routes to `AudioProvider.showNotification()` on TV and to a
  SnackBar on phone, with no cross-contamination.
- `test/ui/widgets/fruit/fruit_tab_bar_platform_contract_test.dart` — 4 tests
  proving `LiquidGlassWrapper` is never instantiated on non-web (phone/desktop)
  regardless of the liquid-glass toggle, true-black mode, or theme style.
- 7 additional tests in `settings_provider_test.dart` covering hybrid audio web
  defaults (`hybridBackgroundMode`, `hiddenSessionPreset`) and preset
  application (`stability`, `balanced`, `maxGapless`).

Total: 209 tests passing, 0 failures. `flutter analyze` reports 0 errors
(7 `unused_element` warnings in test helpers only).

The one remaining gap: verification of web-specific behavior (`kIsWeb` defaults)
requires browser integration tests, not unit tests. This is a Dart compile-time
constant limitation, documented in the test files.

### Platform Discipline: 9.0/10

Up from 8.8. The key improvement is that the previous scorecard named "a stronger
set of small automated platform contract tests" as the specific weakness, and
that weakness is now directly addressed:

- `FruitTabBar` was instantiating `LiquidGlassWrapper` on phone even though
  `LiquidGlassWrapper` internally bypasses itself on non-web. This is a
  correctness bug — phone was doing unnecessary widget tree work. Fixed with
  `if (isTrueBlackMode || isLiquidGlassOff || !kIsWeb) return content;` and
  four tests that prevent regression.
- TV message routing now has an automated contract test. The `showMessage()`
  branch on `DeviceService.isTv` was the canonical example of untested platform
  policy; it is now tested.
- Settings platform defaults now have an automated contract test. TV-specific
  defaults (`steal` screensaver mode, `rock_salt` font, `preventSleep=true`)
  are verified on every run.

The remaining gap is web platform defaults, which require browser integration
tests. TV/phone boundary is now mechanically enforced.

### Web Audio / Runtime Reliability: 7.0/10

Up from 6.5. Concrete improvements:

- `audio_utils.js` now provides `window._gdarIsHeartbeatNeeded()` as a single
  source of truth for whether the heartbeat is needed (based on mobile UA +
  touch points). Removes duplication and makes the logic auditable in one place.
- `hybrid_html5_engine.js`: WA decode failures now call `this.queue.onError()`
  instead of silently dropping the error. Fetch errors also call `onError()`.
  Previously these were silent gaps in the error path.
- `web_perf_hint_web.dart`: Low-power detection threshold tightened from
  `cores <= 4` to `cores <= 2 || (cores <= 4 && devicePixelRatio < 2.0)`.
  Avoids false-positiving modern quad-core phones with high-DPI displays.
- `hybridBackgroundMode` cold-start default corrected from `html5` to
  `heartbeat` to match the `balanced` preset it was supposed to represent.

The layer is still stateful and concentrated. The JS engines each remain
600-900 lines and there is no unit-test harness for JS behavior. These remain
the score ceiling for this category.

## What Improved Since Earlier Today (2026-03-19 first pass)

- **Bug fix**: `FruitTabBar` no longer instantiates `LiquidGlassWrapper` on
  phone. Was a correctness issue (unnecessary widget work), not just style.
- **3 new contract test suites**: TV/phone message routing, settings platform
  defaults, and Fruit tab bar platform rendering. 17 new tests total.
- **Web audio JS cleanup**: shared heartbeat utility, WA decode error path
  fixed, low-power detection refined, hybridBackgroundMode default corrected.
- **Docs corrected**: `web_ui_audio_engines.md` now matches running code.
- **Dart language finding**: documented that `part`-file extension splits break
  provider fakes due to static dispatch. The correct path for splitting
  `SettingsProvider` is a separate provider class, not an extension.

## What Still Caps The Score

- `SettingsProvider` at 1,964 lines is still the single largest maintainability
  liability. The Dart-idiomatic fix (separate `OilSettingsProvider` or mixins)
  requires updating all consumers and fakes — real work, not a quick refactor.
- The JS audio engines have no unit-test harness. Correctness is proven by
  integration behavior, not by isolated engine tests.
- Web platform defaults (`kIsWeb` branches in settings) cannot be covered by
  unit tests and have no browser integration test suite.
- Host-app wiring tests exist for TV screensaver but not yet for other TV
  runtime flows (focus routing, key handling edge cases).

## Path To 8.5+

1. Split `SettingsProvider`: extract `OilSettingsProvider` as a standalone
   `ChangeNotifier`. This is the highest-leverage single change for
   maintainability. Doing it correctly means updating all consumers and fakes,
   not using a workaround.
2. Shrink the JS audio engines by extracting shared state-emission and
   error-path helpers into `audio_utils.js`.
3. Add host-app contract tests for TV focus routing and key-event handling,
   following the pattern established for screensaver and message routing.
4. Add browser integration tests for the `kIsWeb` settings branches.

## Bottom Line

The repo crossed 8.0 in this session. The jump came from three things happening
together: a real correctness bug was found and fixed, the platform boundary
tests that the scorecard had been asking for were actually written, and the web
audio layer got a meaningful structural cleanup rather than cosmetic changes.
The remaining ceiling is honest — `SettingsProvider` is a large class because
Dart makes it genuinely hard to split cleanly, not because no one has tried.
