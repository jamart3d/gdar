# Audio Graph Modes - Design and Implementation Notes

Session context: 2026-03-19 / 2026-03-20
Audit refresh: 2026-03-21

---

## Overview

The TV screensaver audio graph (`StealGraph`) supports multiple display modes
driven by the Android Visualizer pipeline, with optional stereo VU support from
`AudioPlaybackCapture`.

All modes are selected via `oilAudioGraphMode` in `SettingsProvider` and
rendered by `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`.

| Mode | Description |
|---|---|
| `off` | No graph |
| `corner` | 8-band FFT bars plus BEAT bar, bottom-left |
| `corner_only` | Corner bars plus VU meters plus oscilloscope |
| `circular` | 8-band radial EQ orbiting the logo |
| `ekg` | Scrolling guitar-range EKG line across the bottom |
| `circular_ekg` | Circular EKG orbiting the logo |
| `vu` | Dual analog VU meters only |
| `scope` | Standalone oscilloscope strip |
| `beat_debug` | Diagnostic beat detector panel |

---

## Beat Detection

### Current status

Beat detection is wired through the native plugin and drives:

- the BEAT bar in `corner`
- beat flash in `scope`
- `game.beatPulse`, which feeds screensaver pulse effects
- the `beat_debug` panel

It is still not reliable enough to treat as production-quality beat locking on
real TV hardware.

### Current native implementation

Current Kotlin code in
`apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
does not use the older bass-only EMA detector described in previous notes.

It currently runs 6 detector variants on peak-normalized 3-band signals:

- `0 BASS` - normalized bass vs rolling mean
- `1 MID` - normalized mid vs rolling mean
- `2 BROAD` - `(bass + mid) / 2` vs rolling mean
- `3 ALL` - all-band average vs rolling mean
- `4 EMA` - normalized mid vs EMA background
- `5 TREB` - normalized treble vs rolling mean

The final `isBeat` currently comes from `MID`, not from the EMA variant.

### Thresholds

Mean-threshold detector variants currently use:

```text
adaptiveMultiplier = 1.2 + (1.0 - beatSensitivity) * 1.0
```

So:

- sensitivity `1.0` -> `1.2x`
- sensitivity `0.5` -> `1.7x`
- sensitivity `0.0` -> `2.2x`

The EMA variant uses a different threshold:

```text
sig1 > midEmaVal * (1.0 + (1.0 - beatSensitivity) * 0.5)
```

### Important caveat: `beat_debug` is still diagnostic

The `beat_debug` panel currently shows real `beatAlgos` flags, but its
continuous `algoLevels` bars are still placeholder diagnostic values:

```text
algoLevels = overall * 3.0
```

That means:

- `LEN:6` proves the payload reaches Flutter
- bar flashing proves detector booleans are flowing through
- continuous bar height does not yet prove real per-algorithm strength

Until `algoLevels` is replaced with real detector telemetry, `beat_debug`
should be treated as a transport/debug screen rather than a final calibration
tool.

### Known limitations

- The Android Visualizer usually runs at about 20 Hz, which is a hard limit on
  onset timing quality.
- The detector still relies on peak-normalized amplitudes, which are good for
  graph rendering but weaker for onset contrast.
- `bassBoost` is currently applied before bass normalization, so user gain can
  still affect bass-oriented detector behavior.
- The current Flutter `beat_debug` labels are drifted from the native detector
  order and need cleanup.

---

## VU Meters

### Current behavior

VU mode is no longer fake stereo only.

It now has two paths:

1. Real stereo path:
   - uses `AudioPlaybackCapture` via `StereoCapture.kt`
   - computes RMS independently for `waveformL` and `waveformR`
   - shows `ST` range labels in the VU panel
2. Fallback path:
   - splits FFT bands `0-3` to left and `4-7` to right
   - shows `LO` and `HI` range labels

### Layout

Two analog needle meters, centered near the bottom:

- left meter: `L`
- right meter: `R`

### Ballistics

```dart
_vuRiseSmoothing = 12.0
_vuFallSmoothing = 2.2
_vuPeakDecayPerSec = 0.5
```

### Signal scaling

Fallback FFT fake stereo uses a `1.5x` boost.

Real stereo RMS uses a `2.5x` boost to map typical PCM levels into a readable
needle range.

### Visual zones

- green: `0-65%`
- yellow: `65-82%`
- red: `82-100%`

Needle color tracks the zone, and a peak-hold dot shows the recent maximum.

---

## Oscilloscope

### Source path

The scope currently uses `energy.waveform`, which comes from Android Visualizer
waveform capture through `onWaveFormDataCapture`.

It does not currently use `StereoCapture.waveformL` or `waveformR`.

### Real PCM path

When Visualizer waveform capture is not flat, the scope renders:

- `OSC PCM 256pt`
- downsampled mono waveform
- phosphor trace with beat flash tint/thickness

### Fallback path

When Visualizer waveform data is near-flat, the scope falls back to an
FFT-synthesized waveform derived from the 8 graph bands.

The label shows:

- `OSC FFT-SYN 8B`

This keeps the scope visually alive even on chipsets where Visualizer PCM is not
useful.

### Silent state

If there is no usable signal at all, the scope renders a flat line:

- `OSC - SILENT`

---

## `corner_only` Combined Layout

`corner_only` shows all three displays together in one bottom strip:

```text
[ bar graph ]   [ L VU | R VU ]   [ oscilloscope ]
  left side         centered          right side
```

Approximate layout:

- left panel: corner bars
- center panel: dual VU
- right panel: scope panel, width about `220px`

The scope is right-anchored so it mirrors the left graph panel visually.

---

## Android Capture Notes

### Visualizer path

- capture rate: usually about `20 Hz`
- FFT capture size: max available capture size
- waveform path: mono
- graph bars and scope waveform come from this path

### Stereo path

Stereo VU support is now implemented separately through
`AudioPlaybackCapture`:

- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MainActivity.kt`

This path is used for VU meters when permission is granted, but not yet for
scope rendering or final beat detection.

---

## Tuning Knobs

These are pushed live from Flutter through `updateConfig`.

| Knob | Range | Effective default | Effect |
|---|---|---|---|
| `peakDecay` | `0.990-0.999` | `0.992` from settings | Peak normalization decay speed |
| `bassBoost` | `1.0-3.0` | `1.6` from settings | Boosts bass before normalization; currently affects bass detector inputs too |
| `reactivityStrength` | `0.5-2.0` | `1.1` from settings | Global scale on visible band outputs |
| `beatSensitivity` | `0.0-1.0` | `0.80` from settings | Controls mean-threshold detector variants and the EMA variant |

Notes:

- The Kotlin field initializers are not the same thing as the long-lived
  effective settings defaults.
- Settings are pushed after startup from `ScreensaverScreen`.

---

## Current Reliability Read

The safest interpretation of the current system is:

- graph modes are implemented and mostly accurate
- VU mode now supports real stereo with fallback
- scope fallback is implemented and useful
- beat detection is present but still weak
- `beat_debug` is useful for connectivity checks, not final detector tuning

---

## Recommended Next Cleanup

1. Replace placeholder `algoLevels` with real detector telemetry.
2. Align `beat_debug` labels with native detector order.
3. Update on-screen threshold guides to match current math.
4. Move beat detection toward a hybrid or PCM-backed detector.
