# Autocorrelation Beat Detection Improvements — Design Spec

**Date:** 2026-04-05
**Source todos:** `docs/tv_beat_detection_todo_2026-04-05.md` items 1–4
**Files affected:** `VisualizerPlugin.kt`, `VisualizerAudioReactor.dart`, `SettingsProvider` (initialization + state), `appearance_section_build.dart`

---

## Problem Summary

Jules' autocorrelation beat detection (merged `b87e230`) has four issues:

1. **Unconditional override** — `autocorrBpm` silently replaces `trackedBeatBpm` whenever it fires, regardless of which has higher confidence.
2. **20Hz fallback is too coarse** — ±30 BPM resolution at 120 BPM. Not useful; should be removed.
3. **Unguarded O(n²) loop** — Up to 512 × lagRange iterations per frame with no cap or comment.
4. **Draft TODO** — Jules left "You could do a second pass…" as a comment. Needs to be implemented as a real, toggleable feature.

---

## Architecture

### Phase 1 — Kotlin-only (VisualizerPlugin.kt)

All algorithm changes are self-contained in native code. No Flutter changes until Phase 2.

#### Step 1 — Confidence gate

Only use `autocorrBpm`/`autocorrIbiMs` when the tracked grid has low confidence:

```
val useAutocorr = autocorrBpm != null &&
    (trackedGridConfidence == null || trackedGridConfidence!! < 0.4)
"beatBpm"    to if (useAutocorr) autocorrBpm else trackedBeatBpm
"beatIbiMs"  to if (useAutocorr) autocorrIbiMs else trackedBeatIbiMs
```

Threshold `0.4`: tracked grid is reliable above this (has ≥3 intervals, stable jitter). Below it, autocorr is a better signal than a half-warmed grid.

#### Step 2 — Remove 20Hz fallback

Delete entirely:
- `fallbackRmsHistory`, `fallbackRmsHistoryIndex`, `fallbackRmsHistoryCount` fields
- RMS collection block in `downsampleWaveform`
- `useFallbackRms` branch and `RMS_HISTORY_SIZE` constant
- Reset calls in `start()`

Autocorr only runs when `useStereoRms` is true (requires stereo PCM at 100Hz).

#### Step 3 — Guard the inner loop

Cap the working count before the correlation loop:

```kotlin
// Cap to 256 samples (2.56s at 100Hz) — worst-case O(256 × 67) ≈ 17k ops/frame
val count = minOf(if (useStereoRms) stereoCapture.rmsHistoryCount else 0, 256)
```

Add the comment documenting the cost bound.

#### Step 4 — Second-pass refinement (two modes)

Add two fields, both defaulting to `false`, updated via `updateConfig`:

```kotlin
private var autocorrSecondPass = false
private var autocorrSecondPassHq = false
```

**Sabrina hardware gate** — detected once at class init:
```kotlin
private val isSabrinaDevice = Build.DEVICE.lowercase() == "sabrina"
```
If `isSabrinaDevice`, force `autocorrSecondPassHq = false` regardless of what Flutter sends.

**Mode A — Parabolic interpolation** (cheap, safe on Sabrina):
When `autocorrSecondPass && bestLag > 0`:
```kotlin
val cPrev = corrAtLag(bestLag - 1)
val cBest = corrAtLag(bestLag)
val cNext = corrAtLag(bestLag + 1)
val denom = cPrev - 2.0 * cBest + cNext
val refinedLag = if (denom < 0.0) bestLag + 0.5 * (cPrev - cNext) / denom else bestLag.toDouble()
```
Gives sub-sample precision at ~3 extra lookups.

**Mode B — HQ upsampled re-search** (expensive, Sabrina-disabled):
When `autocorrSecondPass && autocorrSecondPassHq && !isSabrinaDevice`:
- Linearly interpolate `rawRms` to 4× rate (400Hz) in a ±3-sample window around `bestLag`
- Re-run narrow correlation on the upsampled window (±3 lags → 6 iterations)
- Use the refined lag from this pass

Both modes store the refined lag back as `detectedIbiMs`/`autocorrBpm`.

---

### Phase 2 — Flutter wiring

#### SettingsProvider

Two new prefs with keys:
- `beat_autocorr_second_pass` — bool
- `beat_autocorr_second_pass_hq` — bool

Defaults via `_dBool`:

| Pref | web | tv | phone |
|---|---|---|---|
| `beat_autocorr_second_pass` | false | true | false |
| `beat_autocorr_second_pass_hq` | false | false | false |

HQ defaults to false everywhere — user opt-in only. The Kotlin Sabrina gate is the safety net; Flutter default-false is a second layer.

Public getters:
```dart
bool get beatAutocorrSecondPass => _beatAutocorrSecondPass;
bool get beatAutocorrSecondPassHq => _beatAutocorrSecondPassHq;
```

Toggle methods:
```dart
Future<void> toggleBeatAutocorrSecondPass() async { ... notifyListeners(); }
Future<void> toggleBeatAutocorrSecondPassHq() async { ... notifyListeners(); }
```

#### VisualizerAudioReactor.dart

Add two params to `updateConfig`:
```dart
void updateConfig({
  ...
  bool? autocorrSecondPass,
  bool? autocorrSecondPassHq,
}) { ... }
```

Pass them through to Kotlin via `_methodChannel.invokeMethod('updateConfig', {...})`.

Two call sites need updating:

1. **`screensaver_screen.dart` `_pushAudioConfig`** — add `beatAutocorrSecondPass` and `beatAutocorrSecondPassHq` to the read, unchanged-check, call, and last-pushed tracking (mirrors the existing `beatSensitivity` pattern exactly).

2. **`tv_screensaver_preview_panel.dart`** — two `updateConfig` calls (lines ~94 and ~165), both need the new params added.

#### VisualizerPlugin.kt — updateConfig handler

```kotlin
autocorrSecondPass = call.argument<Boolean>("autocorrSecondPass") ?: autocorrSecondPass
// HQ is always overridden to false on Sabrina
val requestedHq = call.argument<Boolean>("autocorrSecondPassHq") ?: autocorrSecondPassHq
autocorrSecondPassHq = if (isSabrinaDevice) false else requestedHq
```

#### TV Settings UI — Appearance section

Add to `appearance_section_build.dart` inside `_buildAppearanceSection`, guarded by `isTv`:

```dart
if (context.read<DeviceService>().isTv) ...[
  _buildAutocorrSecondPassTile(context, settingsProvider),
  if (settingsProvider.beatAutocorrSecondPass)
    _buildAutocorrSecondPassHqTile(context, settingsProvider),
],
```

`_buildAutocorrSecondPassTile` — `TvSwitchListTile`:
- Title: `'Beat Precision Refinement'`
- Subtitle: `'Improves BPM accuracy when no beat grid is locked'`
- Value: `settingsProvider.beatAutocorrSecondPass`
- `onChanged`: `settingsProvider.toggleBeatAutocorrSecondPass()`

`_buildAutocorrSecondPassHqTile` — `TvSwitchListTile`, shown only when second pass is on:
- Title: `'High-Quality Refinement'`
- Subtitle: `'Higher accuracy, more compute. Not available on all devices.'`
- Value: `settingsProvider.beatAutocorrSecondPassHq`
- `onChanged`: `settingsProvider.toggleBeatAutocorrSecondPassHq()`
- Disabled (grayed) when `isSabrinaDevice` — but since Sabrina enforcement is in Kotlin, Flutter just shows the toggle as normal; the Kotlin layer silently ignores it on Sabrina.

---

## Unchanged

- `trackedBeatBpm` / `trackedGridConfidence` logic — untouched
- Beat detection algorithms 0–5 — untouched
- `StereoCapture.kt` — Phase 1/2 don't touch it (separate todo items 5–8)
- `autocorrBpm` passthrough key in the data map — kept for debug visibility

---

## Testing

- Confidence gate: unit-testable via mock `stereoCapture.rmsHistoryCount` ≥ 200 and setting `trackedGridConfidence` < / ≥ 0.4
- Fallback removal: verify no `fallbackRmsHistory` references remain
- Loop cap: verify `count` is always ≤ 256 in autocorr block
- Second pass: verify parabolic result is within ±0.5 lag of integer result; verify HQ is forced off when `isSabrinaDevice`
- Settings: standard `SettingsProvider` prefs tests with `isTv: true` constructor
