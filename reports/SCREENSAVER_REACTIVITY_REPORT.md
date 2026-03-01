# Screensaver Reactivity & Fidelity Report
Date: 2026-02-27
Updated: 09:11 AM

## Current Architecture

```
VisualizerPlugin.kt (Kotlin, FFT/RMS + Onset Detection)
  → EventChannel → VisualizerAudioReactor.dart
    → Stream<AudioEnergy> (bass/mid/treble/overall + isBeat + 8-band FFT)
      → StealGame._currentEnergy
        → StealBackground (shader uniforms + beat pulse)
        → StealGraph (8-bar corner EQ or 8-band circular EQ)
```

Fallback path (non-TV): `PositionAudioReactor.dart` → sine wave heuristic.

---

## Analysis & Status

### Completed ✅

| Item | Location | Status |
|:---|:---|:---|
| Beat detection via bass onset | `VisualizerPlugin.kt` | ✅ Done |
| `isBeat` flag + 8 FFT bands in `AudioEnergy` | `audio_energy.dart` | ✅ Done |
| Beat sensitivity tuning knob (native + Dart) | `VisualizerPlugin.kt` → `VisualizerAudioReactor` | ✅ Done |
| Beat pulse on logo scale | `steal_background.dart` | ✅ Done |
| Adjustable beat sensitivity setting + slider UI | `SettingsProvider` / `tv_screensaver_section.dart` | ✅ Done |
| Fix `_sine()` → uses `dart:math sin` | `position_audio_reactor.dart` | ✅ Done |
| Corner graph upgraded from 4 to 8 FFT bars | `steal_graph.dart` | ✅ Done |
| Circular EQ graph (8-band radial) | `steal_graph.dart` | ✅ Done |
| Graph mode selector (Off/Corner/Circular) | `tv_screensaver_section.dart` | ✅ Done |
| 8-band FFT output from native | `VisualizerPlugin.kt` | ✅ Done |

### Remaining TODO 📋

| Item | Location | Priority |
|:---|:---|:---|
| Reduce smoothing (`0.6`) for snappier response | `VisualizerPlugin.kt:35` | Medium |
| Peak normalization kills dynamics (quiet = loud) | `VisualizerPlugin.kt:198-201` | Medium |
| Shader reactivity (tie `pulseIntensity`/`heatDrift` to beat energy) | `steal_background.dart` | Enhancement |
| Waveform capture mode (Android Visualizer waveform callback unused) | `VisualizerPlugin.kt` | Enhancement |
| Trail reactivity (increase trail intensity during high energy) | `steal_background.dart` | Enhancement |

---

## Recommendations Summary

### Recommendation 1: Beat Detection + Logo Pulse — ✅ DONE
Onset detection in `VisualizerPlugin.kt` compares current bass energy to running average. Emits `isBeat: true` when threshold exceeded. Configurable **Beat Sensitivity** slider (0.0–1.0) in settings. Logo pulses via `logoScale` shader uniform boost.

### Recommendation 2: Fix PositionAudioReactor — ✅ DONE
`_sine()` now uses `dart:math.sin()`. `_random()` replaced with `dart:math.Random`.

### Recommendation 3: Circular EQ + Graph Mode Toggle — ✅ DONE
Both corner and circular modes now render 8 FFT bands. `SegmentedButton` selector (Off / Corner / Circular) in settings. Corner bars: 8px wide, 4px gap, bottom-left anchored. Circular bars: 6px wide, 40px max height, radial from center.
