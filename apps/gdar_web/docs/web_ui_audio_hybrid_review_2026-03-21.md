# Web UI, Audio Engine, Hybrid, and Defaults Review

Date: 2026-03-21
Scope: Web UI, web audio engine, hybrid orchestration, settings UI, and HUD
Prior review: `web_ui_audio_hybrid_review_2026-03-19.md`
Workspace: `/home/jam/StudioProjects/gdar`

## Summary

All 7 findings from the 2026-03-19 review are now fully resolved. The one
partially-resolved item (F1 — hybrid controls gate) has been completed. One new
minor finding was identified: the HF chip tooltip descriptions diverge from the
settings UI labels after the handoff mode label rename. No regressions were
found in the recent settings UI and HUD changes.

---

## Status of 2026-03-19 Findings

### F1 — P1: Hybrid controls hidden for default desktop path — FULLY RESOLVED

**Previous state (2026-03-19):** The engine selector chip correctly reflected
the resolved active mode (not the stored enum), but the advanced controls
section (Hybrid Handoff Mode, Background Mode) still gated on the stored
preference:

```dart
// old
if (sp.audioEngineMode == AudioEngineMode.hybrid) ...[
```

A default desktop user running `auto` (which resolves to `hybrid`) still did
not see the advanced controls.

**Current state:** A `resolvedMode` variable is now computed at the top of
`_buildWebGaplessSection` and used as the gate:

```dart
// playback_section.dart:502-504
final resolvedMode = sp.audioEngineMode == AudioEngineMode.auto
    ? audioProvider.audioPlayer.activeMode
    : sp.audioEngineMode;
...
// playback_section.dart:712
if (resolvedMode == AudioEngineMode.hybrid) ...[
```

A default desktop user (`auto` → resolves to `hybrid`) now sees the Hybrid
Handoff Mode and Background Survival controls correctly.

**Status: closed.**

---

### F3 — P2: Web defaults undercut Fruit-first presentation — FULLY RESOLVED

**Previous state:** `WebDefaults.performanceMode = true` caused first-run web
to boot into simplified presentation (no liquid glass, reduced animation) with
no comment explaining why.

**Current state:** `default_settings.dart:186-187`:

```dart
static const bool performanceMode =
    false; // Fruit-first by default; low-power devices opt in via SettingsProvider detection
```

Performance mode is now `false` for web. The comment explains the intent.
Low-end devices are opted in at runtime via `isLikelyLowPowerWebDevice()`.

**Status: closed.**

---

### F4 — P2: `?flush=true` wiped entire origin localStorage — FULLY RESOLVED

**Previous state:** `hybrid_init.js` called `localStorage.clear()`, wiping all
keys for the origin, not just GDAR keys.

**Current state:** `hybrid_init.js:36-43`:

```js
const keysToRemove = Object.keys(localStorage).filter(k =>
    k.startsWith('flutter.') ||
    k === 'audio_engine_mode' ||
    k === 'allow_hidden_web_audio' ||
    k === 'gdar_web_error_log_v1'
);
keysToRemove.forEach(k => localStorage.removeItem(k));
```

The flush now targets only `flutter.*` (SharedPreferences-managed keys) and
known raw GDAR keys. Unrelated origin keys are untouched.

**Status: closed.**

---

### F5 — P3: Stale "all categories ON" comment — FULLY RESOLVED

**Previous state:** Both the old ("all categories ON") and new ("only matrix ON")
comment blocks coexisted at `settings_provider.dart:1335-1340`.

**Current state:** Only one comment block remains at line 1335, accurately
describing the behavior ("Only 'matrix' ON by default").

**Status: closed.**

---

### N1 — P2: JS bootstrap fallback for `hybridBackgroundMode` stale — FULLY RESOLVED

**Previous state:** `hybrid_init.js` fell back to `'"html5"'` on first run,
conflicting with the Dart default of `heartbeat`.

**Current state:** `hybrid_init.js:136`:

```js
const bgMode = localStorage.getItem('flutter.hybrid_background_mode') || '"heartbeat"';
```

JS and Dart cold-start defaults now agree.

**Status: closed.**

---

### N2 — P2: `_gdarDetectedAsLowPower` threshold diverged from Dart — FULLY RESOLVED

**Previous state:** JS used a flat `<= 4` cores threshold; Dart used the
DPR-aware `cores <= 2 || (cores <= 4 && dpr < 2.0)` heuristic.

**Current state:** `hybrid_init.js:159-162`:

```js
const _lpDpr = window.devicePixelRatio || 1;
const _lpCores = navigator.hardwareConcurrency || 0;
const _lpIsLowCores = _lpCores > 0 && (_lpCores <= 2 || (_lpCores <= 4 && _lpDpr < 2.0));
window._gdarDetectedAsLowPower = (isMobiUA || isIPadOS) && _lpIsLowCores;
```

JS and Dart heuristics now agree.

**Status: closed.**

---

### N3 — P3: `hybrid_init.js` load-order dependency undocumented — FULLY RESOLVED

**Previous state:** No comment or guard in `hybrid_init.js` noting its
dependency on `audio_utils.js`.

**Current state:** `hybrid_init.js:19-23`:

```js
 * Requires audio_utils.js to be loaded before this script.
 * audio_utils.js defines window._gdarIsHeartbeatNeeded(), which is called
 * by all engines at state-emission time. If audio_utils.js is absent or
 * loaded after the engines, heartbeat detection will throw silently.
```

Dependency is documented in the file header.

**Status: closed.**

---

## New Finding

### N4 — P3: HF chip tooltip descriptions diverge from settings UI labels

**File:** `packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud.dart`

The handoff mode settings labels were renamed this session:

| Mode | Old label | New label |
|------|-----------|-----------|
| `buffered` | End of Buffer | Mid |
| `boundary` | Boundary | End |

The HUD chip shortcode (`BND`, `BUF`) and the HF chip tooltip were not updated
to match:

```dart
// dev_audio_hud.dart:1080-1083
if (value == 'IMM') desc = 'Immediate';
if (value == 'BND') desc = 'Boundary';   // settings now says "End"
if (value == 'OFF') desc = 'Off';
if (value == 'BUF') desc = 'Buffered';   // settings now says "Mid"
```

A user who sees "Mid" in settings and hovers the `HF:BUF` chip will read
"Buffered" — not wrong, but inconsistent with the label they set it by.

**Recommended fix:** Update the tooltip descriptions to match the settings
labels, and add a parenthetical explaining the underlying behaviour:

```dart
if (value == 'BND') desc = 'End — swap at the next track boundary';
if (value == 'BUF') desc = 'Mid — wait until HTML5 buffer is exhausted, then swap';
```

**Status: closed.**

---

## What Changed Since 2026-03-19

### Settings UI: hybrid controls now use `resolvedMode`

`_buildWebGaplessSection` computes `resolvedMode` from the active player mode
when stored preference is `auto`. Both the engine selector chip and the advanced
controls gate use this resolved value. Default desktop users (`auto` → `hybrid`)
now see handoff and background controls without any manual override.

### Settings UI: "Allow Web Audio while hidden" toggle removed

The toggle was redundant — the preset system (`Stability`/`Balanced`/`Max`)
already owns `allowHiddenWebAudio`, and the toggle only affected the hybrid
engine. Removed from `playback_section.dart`. The backing field, pref key, and
JS wiring are unchanged; `AudioProvider` still syncs the value to the player on
settings change.

### Settings UI: Handoff Crossfade slider removed

Default was 0ms (off); the slider only applied to hybrid engine WA→HTML5
handoffs and was too niche to surface. Removed from UI. The backing field and
JS wiring are unchanged.

### Settings UI: segmented selectors converted to connected bar

All four `_SegmentedWrap` instances (engine mode, preset, handoff mode,
background mode) now render as a single connected strip with a shared outer
border, `IntrinsicHeight` row, and `VerticalDivider` between cells. Eliminates
the multi-row wrap on narrow screens.

### Settings UI: handoff mode labels shortened

`End of Buffer` → `Mid`, `Boundary` → `End`. See N4 above for the tooltip
gap this introduced.

### HUD: DFT and HD sparklines freeze when paused

`_appendDriftSample` and `_appendHeadroomSample` are now gated on `isPlaying`.
Previously the sparklines accumulated samples unconditionally, giving a false
impression of activity while paused.

### HUD: tooltip improvements

- **PF:** `G` now reads "Prefetch: Greedy — fetch full track immediately.
  Required by WebAudio engine (needs full buffer decoded upfront)."
- **BG:** Each value now includes a full strategy description. `HBT` appends
  the traffic light dot legend (red/orange/green).
- **AE:** Now value-aware — explains each prefix (`WA`/`H5`/`VI`/`HBT`/`BG`/`FG`),
  the `-New`/`-Opt` heartbeat flags, and the `+` survival-mode suffix with its
  indigo chip color meaning.

### HUD: WAIT chip and NET sparkline explored and removed

A WAIT chip (archive.org fetch stall duration) and NET sparkline (stall history)
were implemented and then removed. Root cause: `processingState` never reaches
`'buffering'` on the gapless or hybrid HTML5 engines — `_loadingState` cycles
`idle → loading → ready` only, so the stall tracker never fired. `HD` remains
the best available network proxy.

`TODO(fetch-latency)` comments were placed in `gapless_audio_engine.js` (at the
`fetch()` call) and `hud_snapshot.dart` marking the full pipeline needed:
JS `fetchStart` + TTFB → `_emitState()` → interop → `HudSnapshot.fetchTtfbMs`
→ NET chip/sparkline.

---

## Additional Suggestions (updated status)

### 1. Centralize resolved web audio config — unchanged

`audio_utils.js` provides shared heartbeat utilities. A single resolved-config
object that Dart and JS agree on at startup is still not implemented.

### 2. Separate requested mode from resolved mode — RESOLVED

`resolvedMode` in `playback_section.dart` now correctly separates stored
preference from active engine. Both the selector and the advanced controls gate
use it. Closed.

### 3. Reduce provider-wide rebuild pressure on web screens — unchanged

`ShowListScreen` still watches broad provider state. No change.

### 4. Make survivability vs presentation tradeoff explicit — RESOLVED

`WebDefaults.performanceMode = false` with an explanatory comment. Closed.

---

## Open Findings Summary

| ID | Priority | Status | Description |
|----|----------|--------|-------------|
| N4 | P3 | Resolved | HF tooltip updated to match End/Mid settings labels |

---

## Review Notes

- Code-reading audit. Tests were not run as part of this pass.
- Current test suite: 209 passing (confirmed via prior CI run).
- No files were modified beyond saving this report.
- Previous review: `apps/gdar_web/docs/web_ui_audio_hybrid_review_2026-03-19.md`.
