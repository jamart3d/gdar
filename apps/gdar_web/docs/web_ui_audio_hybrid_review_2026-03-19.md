# Web UI, Audio Engine, Hybrid, and Defaults Review

Date: 2026-03-19
Scope: Web UI, web audio engine, hybrid orchestration, and default settings
Prior review: `web_ui_audio_hybrid_review_2026-03-17.md`
Workspace: `/home/jam/StudioProjects/gdar`

## Summary

This is a re-audit of the same scope as the 2026-03-17 review. Four of the five
original findings have been addressed to varying degrees, and three new issues
were found during this pass. The overall picture is meaningfully cleaner: dead
config is gone, the heartbeat detection logic is centralized, error paths that
were silent are now wired, and the docs are accurate. The remaining gaps are
smaller and more precise than they were two days ago.

---

## Status of 2026-03-17 Findings

### P1: Hybrid controls hidden for default desktop path — PARTIALLY RESOLVED

**Original finding:** Hybrid handoff/background controls only rendered when the
stored setting was explicitly `AudioEngineMode.hybrid`. Default desktop runs
`auto`, which resolves to `hybrid`, so the controls were hidden for most users.

**What changed:**

The engine selector's `selectedValue` was updated to use
`audioPlayer.activeMode` when the stored preference is `auto`:

```dart
// playback_section.dart:591-593
selectedValue: sp.audioEngineMode == AudioEngineMode.auto
    ? context.read<AudioProvider>().audioPlayer.activeMode
    : sp.audioEngineMode,
```

This means the selector chip now correctly highlights the running engine even
when the stored value is `auto`.

**What remains:**

The advanced controls section (Hybrid Handoff Mode, Background Mode) still
gates on the stored preference, not the resolved mode:

```dart
// playback_section.dart:707
if (sp.audioEngineMode == AudioEngineMode.hybrid) ...[
```

A default desktop user running `auto` (which resolves to `hybrid`) still does
not see the Hybrid Handoff Mode or Background Mode controls. The selector shows
correctly; the dependent controls do not follow.

**Recommended fix (unchanged):** Gate the hybrid controls on the resolved active
mode, not the stored enum. The information is already available:
`context.read<AudioProvider>().audioPlayer.activeMode == AudioEngineMode.hybrid`.

---

### P1: `hybridForceHtml5Start` dead config — FULLY RESOLVED

**Original finding:** `hybridForceHtml5Start` was defined in Dart defaults,
persisted by `SettingsProvider`, referenced in presets, synced through
`AudioProvider`, and exposed via JS interop — but the JS engine never consumed
it.

**What changed:**

The flag has been completely removed. It no longer appears in:
- `default_settings.dart`
- `settings_provider.dart`
- `audio_provider.dart`
- `gapless_player_web.dart`
- `hybrid_audio_engine.js`
- `web_ui_audio_engines.md`
- Any preset or adaptive profile logic

No references remain in the Dart or JS runtime code. The doc was also corrected
to remove all references to the flag from preset tables.

**Status: closed.**

---

### P2: Web defaults undercut Fruit-first presentation — UNCHANGED

**Original finding:** `WebDefaults.performanceMode = true` causes the first-run
web experience to boot into simplified presentation (no liquid glass, reduced
animation) despite the app presenting as Fruit-first.

**Current state:** `WebDefaults.performanceMode = true` remains in
`default_settings.dart:185`. No change.

The adaptive web profile (`modern` path) applies `hybridBackgroundMode =
heartbeat` and `hiddenSessionPreset = balanced` on first run, but it does not
change `performanceMode`. A new web user on a capable desktop still boots into
the simplified theme.

**Recommended fix (unchanged):** Either default `performanceMode = false` for
web and let `isLikelyLowPowerWebDevice()` opt low-end devices in, or make the
tradeoff explicit in the `WebDefaults` comment. The current state implies
Fruit-first but delivers performance-first silently.

---

### P2: `?flush=true` clears all localStorage for the origin — UNCHANGED

**Original finding:** `hybrid_init.js` calls `localStorage.clear()` which erases
all localStorage keys for the origin, not just GDAR keys.

**Current state:** The code is unchanged at `hybrid_init.js:29`:

```js
localStorage.clear();
```

The session-guard (`shakedown_flushed`) prevents it from firing more than once
per session, but the blast radius of the clear itself is still the entire
origin.

**Recommended fix (unchanged):** Restrict the clear to known prefixes:
`flutter.` for SharedPreferences-managed keys and any raw GDAR keys used
directly (e.g. `audio_engine_mode`).

---

### P3: Source filter comments and behavior out of sync — PARTIALLY RESOLVED

**Original finding:** Comments described an "all categories ON" web override, but
the actual behavior only enabled `matrix`.

**What changed:**

A corrected comment block was added, but the old comment block was not removed.
Both now coexist at `settings_provider.dart:1335-1340`:

```dart
// Web-only override: all categories ON by default.          ← OLD (stale)
// We use a one-time migration check to ensure existing web users also get
// all categories enabled, while preserving their future custom choices.
// Web-only override: Only 'matrix' ON by default for a curated first experience.  ← NEW (correct)
// We use a one-time migration check to ensure new web users start with matrix,
// while preserving their future custom choices.
```

The actual behavior (only `matrix` enabled) is correct. The stale "all
categories ON" comment should be removed.

**Recommended fix:** Delete lines 1335-1337 (the old comment block). The new
comment on lines 1338-1340 accurately describes the behavior.

---

## New Findings

### N1 — P2: JS bootstrap fallback for `hybridBackgroundMode` is stale

**File:** `apps/gdar_web/web/hybrid_init.js:123`

The JS bootstrap reads `hybridBackgroundMode` from localStorage when wiring the
hybrid engine on startup. If the key is absent, it falls back to a hardcoded
value:

```js
const bgMode = localStorage.getItem('flutter.hybrid_background_mode') || '"html5"';
```

The Dart layer was updated this session so that the cold-start default for
`hybridBackgroundMode` is `heartbeat` (`settings_provider.dart:1054`):

```dart
_prefs.getString(_hybridBackgroundModeKey) ?? 'heartbeat',
```

On a fresh install the typical flow is:

1. `hybrid_init.js` runs first — key is absent — JS engine starts with `html5`
2. Flutter initializes — Dart defaults to `heartbeat` — writes `heartbeat` to
   localStorage

The engine is already running from step 1 before Dart finishes initializing, so
the first session starts with `html5` background mode even though the Dart
default is `heartbeat`. Subsequent sessions are correct because the key is now
persisted.

**Recommended fix:** Change the JS fallback to match the Dart default:

```js
const bgMode = localStorage.getItem('flutter.hybrid_background_mode') || '"heartbeat"';
```

---

### N2 — P2: `_gdarDetectedAsLowPower` threshold diverged from Dart

**File:** `apps/gdar_web/web/hybrid_init.js:146-147`

```js
window._gdarDetectedAsLowPower = (isMobiUA || isIPadOS) &&
    navigator.hardwareConcurrency > 0 && navigator.hardwareConcurrency <= 4;
```

This session refined the Dart-side low-power heuristic in
`web_perf_hint_web.dart` to:

```dart
final isLowCoreCount = cores > 0 && (cores <= 2 || (cores <= 4 && dpr < 2.0));
```

The JS diagnostic signal now uses the old threshold (`<= 4` cores flat), while
the Dart heuristic uses the refined threshold (DPR-aware). The two detection
points will disagree for a modern quad-core phone with a high-DPI screen: Dart
correctly classifies it as not low-power; the JS flag says it is.

`_gdarDetectedAsLowPower` is a diagnostic/informational flag exposed to Dart for
HUD display, so this is a display inconsistency rather than a behavioral bug.
Still, a contradictory classification makes the HUD harder to trust.

**Recommended fix:** Update `hybrid_init.js` to match:

```js
const dpr = window.devicePixelRatio || 1;
const cores = navigator.hardwareConcurrency || 0;
const isLowCores = cores > 0 && (cores <= 2 || (cores <= 4 && dpr < 2.0));
window._gdarDetectedAsLowPower = (isMobiUA || isIPadOS) && isLowCores;
```

---

### N3 — P3: `hybrid_init.js` has no comment explaining the `_gdarIsHeartbeatNeeded` dependency

**File:** `apps/gdar_web/web/hybrid_init.js`

The bootstrap file depends on `window._gdarIsHeartbeatNeeded` being present
(defined in `audio_utils.js`). This dependency is load-order-sensitive: if
`audio_utils.js` is removed from `index.html` or reordered, the heartbeat
detection silently fails (the function is undefined and calls would throw). The
bootstrap itself has no comment or guard noting this dependency.

This is a low-severity maintenance risk, not a current bug.

**Recommended fix:** Add a guard or comment near the top of `hybrid_init.js`:

```js
// Requires audio_utils.js to be loaded first (defines window._gdarIsHeartbeatNeeded)
```

Or add a runtime guard:

```js
if (typeof window._gdarIsHeartbeatNeeded !== 'function') {
    console.warn('[Shakedown] audio_utils.js not loaded — heartbeat detection unavailable');
    window._gdarIsHeartbeatNeeded = () => false;
}
```

---

## What Improved Since 2026-03-17

These items are not findings — they are positive changes observed during this
audit pass.

### Heartbeat detection centralized (`audio_utils.js`)

`window._gdarIsHeartbeatNeeded()` now lives in a single shared utility, cached
on `window._gdarHeartbeatNeeded` after first call. All engines
(`hybrid_html5_engine.js`, `passive_audio_engine.js`) use the shared function
instead of the 15+ inline copies of the mobile UA + `maxTouchPoints` lambda.

### WA decode error path wired (`hybrid_html5_engine.js`)

Web Audio decode failures and fetch errors now call `this.queue.onError()`.
Previously these paths were silent — the engine would silently drop the error
and leave the queue in an inconsistent state.

### Low-power detection refined (`web_perf_hint_web.dart`)

The Dart heuristic now uses `cores <= 2 || (cores <= 4 && dpr < 2.0)` instead
of the flat `cores <= 4` threshold. Modern quad-core phones with high-DPI
displays are no longer false-positived as low-power.

### `hybridBackgroundMode` Dart default corrected

The cold-start Dart default was `html5` but the `balanced` preset (applied on
first-run desktop) targets `heartbeat`. The Dart default is now `heartbeat`,
matching preset intent. (The JS bootstrap fallback remains `html5` — see N1
above.)

### `web_ui_audio_engines.md` now accurate

The doc was updated to remove all references to `hybridForceHtml5Start`, correct
the adaptive profile tables, add a recent-changes section, and document the
`contextState` string format emitted by each engine.

---

## Open Findings Summary

| ID  | Priority | Status      | Description |
|-----|----------|-------------|-------------|
| F1  | P1       | Resolved    | Hybrid controls now gated on resolved active mode, not stored enum |
| F2  | P1       | Resolved    | `hybridForceHtml5Start` dead config — removed |
| F3  | P2       | Resolved    | `WebDefaults.performanceMode = false`; low-power phones get Android theme + performance mode via detection |
| F4  | P2       | Resolved    | `?flush=true` now removes only `flutter.*` and known raw GDAR keys |
| F5  | P3       | Resolved    | Stale "all categories ON" comment removed — correct comment remains |
| N1  | P2       | Resolved    | JS bootstrap fallback updated to `heartbeat` to match Dart default |
| N2  | P2       | Resolved    | `_gdarDetectedAsLowPower` updated to DPR-aware threshold matching Dart heuristic |
| N3  | P3       | Resolved    | Load-order dependency on `audio_utils.js` documented in `hybrid_init.js` header |

---

## Additional Suggestions (from 2026-03-17, updated status)

### 1. Centralize resolved web audio config — partially addressed

`audio_utils.js` now provides a shared heartbeat utility. The broader
suggestion (a single resolved-config object that Dart and JS agree on) is still
not implemented, but the gap is smaller.

### 2. Separate requested mode from resolved mode everywhere — partially addressed

The engine selector's `selectedValue` now respects resolved mode. The advanced
controls gate still uses stored mode. Finishing this requires updating the
`if (sp.audioEngineMode == AudioEngineMode.hybrid)` guard.

### 3. Reduce provider-wide rebuild pressure on web screens — unchanged

`ShowListScreen` still watches broad provider state. No change since 2026-03-17.

### 4. Make the survivability vs presentation tradeoff explicit — unchanged

`WebDefaults.performanceMode = true` is still the silent default. The intent is
not stated in a comment. The tension between Fruit-first UI and
survivability-first defaults remains implicit.

---

## Review Notes

- This was a code-reading audit. Tests were not run as part of this pass (full
  suite: 209 passing, 0 failures, confirmed separately).
- No files were modified beyond saving this report.
- Previous review at `docs/web_ui_audio_hybrid_review_2026-03-17.md`.
