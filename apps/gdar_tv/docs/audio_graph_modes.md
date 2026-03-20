# Audio Graph Modes — Design & Implementation Notes

_Session: 2026-03-19 / 2026-03-20_

---

## Overview

The screensaver audio graph (`StealGraph`) supports multiple display modes driven by
the Android Visualizer API. All modes are selected via `oilAudioGraphMode` in
`SettingsProvider` and rendered by `steal_graph.dart`.

| Mode | Description |
|---|---|
| `off` | No graph |
| `corner` | 8-band FFT bars + BEAT bar, bottom-left |
| `corner_only` | Same as corner + VU meters + oscilloscope (all three combined) |
| `circular` | 8-band radial EQ orbiting the logo |
| `ekg` | Scrolling EKG line, guitar-range (mid 250–2000 Hz) |
| `circular_ekg` | EKG orbiting the logo |
| `vu` | Dual analog VU needle meters only |
| `scope` | Oscilloscope full-screen strip |

---

## Beat Detection

> **STATUS: NOT WORKING RELIABLY**
> Beat detection fires very infrequently and misses the majority of beats during
> normal playback. The BEAT bar in corner mode and the scope flash are both
> driven by this signal — both are essentially non-functional as a result.
> Further work needed; see open questions below.

### Algorithm: EMA Onset Detector (Kotlin `VisualizerPlugin`)

Replaces the original peak-floor tracker that converged to sustained bass
levels and missed beats entirely.

```
bassEma = bassEma * (1 - 0.1) + beatBass * 0.1   // ~0.5s window at 20 Hz
threshold = 1.0 + (1.0 - beatSensitivity) * 0.5  // 1.0–1.5× EMA
isBeat = beatBass > bassEma * threshold
         && (nowMs - lastBeatTimeMs) > 200ms
         && recentBassHistory.size >= 10           // warm-up guard
```

- `beatBass` uses pre-boost raw bass so visual gain does not alter trigger rate
- Min beat gap: 200 ms = max 5 beats/sec, supports up to 150 BPM in 4/4
- Warm-up guard (10 frames) prevents false triggers on startup

### Key fix: `_pushAudioConfig` ordering bug

`start()` was `void` (async internally). Config was being pushed before
`_isRunning = true`, so `beatSensitivity` was silently dropped every time.
Fixed by making `start()` return `Future<void>` and awaiting it in
`screensaver_screen.dart` before calling `_pushAudioConfig`.

### Default sensitivity
`oilBeatSensitivity` default: **0.80** (was 0.45, then 0.65).
Higher = more beats triggered; 1.0 = fires on any bass spike above EMA.

### Open questions / known issues
- The EMA algorithm may be too conservative for live Grateful Dead recordings,
  which have highly variable bass levels and less rigid rhythmic transients than
  studio pop.
- The Android Visualizer only runs at 20 Hz — at that rate, a 120 BPM kick
  drum fires every 500 ms but the visualizer only delivers 10 frames in that
  window. Onset detection at 20 Hz is fundamentally coarse.
- It is unclear whether the PCM flatness issue (see Oscilloscope section) also
  affects the FFT data quality or dynamic range on this specific chipset, which
  could suppress the bass transients that the detector relies on.
- No alternative algorithm (e.g. spectral flux, HFC, complex-domain onset) has
  been tried. The EMA approach was an improvement over the original peak-floor
  tracker but is still not production-quality.

---

## VU Meters

### Layout
Two analog needle meters, centered at bottom, fake stereo split from FFT bands:

- **L needle** (LO): average of bands 0–3 (sub/bass/low-mid)
- **R needle** (HI): average of bands 4–7 (upper-mid/presence/brilliance/air)

### Ballistics
```dart
_vuRiseSmoothing = 12.0   // fast attack
_vuFallSmoothing = 2.2    // slow fall (classic VU ballistic feel)
_vuPeakDecayPerSec = 0.5  // peak-hold dot falls slowly
```

### Signal boost
Band values are compressed by the Kotlin normalizer during long playback.
A **1.5× pre-boost** lifts the needle into the working range without pegging.
(3× was tried and caused needles to slam full-right; 1.5× is the compromise.)

### Visual zones
- Green arc: 0–65% (safe)
- Yellow arc: 65–82% (caution)
- Red arc: 82–100% (over)
- Needle color tracks zone; peak-hold dot shows highest recent level

---

## Oscilloscope

### PCM reality on this device
The Android Visualizer API provides PCM waveform data via
`onWaveFormDataCapture`. On the Google TV (this device), the PCM capture
returns flat/near-zero data even though FFT works correctly. This is a known
chipset limitation.

Waveform capture is **always-on** in the Kotlin plugin (no gating) — earlier
attempts to gate it caused timing bugs where the enable call happened before
`_isRunning = true`.

### Fallback: FFT-band additive synthesis
When `_scopePeak ≤ 0.015` (PCM is flat), the scope synthesizes a waveform
from the 8 FFT bands using additive sinusoidal synthesis:

```dart
// 8 sine components, one per band, scrolling with game.time
const freqs = [0.2, 0.4, 0.7, 1.1, 1.6, 2.25, 3.0, 4.0]; // Hz
const windowSecs = 4.0; // seconds of signal across scope width

for each x-pixel:
  tx = game.time - windowSecs + (x/width) * windowSecs  // left=old, right=new
  val = sum(bands[b] * softClip * sin(2π * freqs[b] * tx)) / 4.0
```

This creates a continuously scrolling, music-reactive waveform:
- Bass-heavy → slow large undulations
- Treble-heavy → fast tight ripples
- Complex music → multi-component complex wave

The scope label shows `OSC FFT-SYN 8B` vs `OSC PCM 256pt` so you can tell
which path is active.

### Soft-clip
`atan(v * 50.0) / (π/2)` — maps tiny PCM values (or band amplitudes) to
visible deflections without hard-clipping. Gain is ~50× for quiet signals,
approaches ±1 asymptotically.

### Beat flash
When `energy.isBeat`, the trace color lerps toward white and the stroke
thickens slightly. `_beatFlash` decays at 3.5/sec (~285ms visible).

---

## `corner_only` Combined Layout

All three displays visible simultaneously, bottom strip:

```
[ bar graph ]   [ L VU | R VU ]   [ oscilloscope ]
  left-anchored    centered          right-anchored
  48px left pad                      48px right pad
  ~122px wide       ~320px wide        220px wide
```

### Scope positioning
Right-anchored to mirror the bar graph panel symmetrically:
```dart
xStart = w - _leftPadding - panelWidth  // panelWidth = 220
```

Panel height matches bar graph: `scopeHeight = _maxBarHeight = 80px`.
Waveform centered vertically in the bar area (`centerY = baseline - 40px`).
Same panel background style (semi-transparent rounded rect + border glow).

---

## Android Visualizer Notes

- Runs at `Visualizer.getMaxCaptureRate()` — typically **20 Hz** (20000 mHz)
- FFT capture size: max available (`Visualizer.getCaptureSizeRange()[1]`)
- PCM: 256 points after downsampling from full capture size
- Audio is **mono** — no L/R stereo split possible via this API
- See `todo_true_stereo_vu.md` for future `AudioPlaybackCapture` approach

---

## Tuning Knobs (live-updatable via `updateConfig`)

| Knob | Range | Default | Effect |
|---|---|---|---|
| `peakDecay` | 0.990–0.999 | 0.998 | How slowly FFT peaks decay |
| `bassBoost` | 1.0–3.0 | 1.0 | Multiplier on raw bass before normalization |
| `reactivityStrength` | 0.5–2.0 | 1.0 | Global scale on all band outputs |
| `beatSensitivity` | 0.0–1.0 | 0.80 | EMA threshold tightness |

Changes pushed from Flutter settings take effect immediately — no restart needed.
