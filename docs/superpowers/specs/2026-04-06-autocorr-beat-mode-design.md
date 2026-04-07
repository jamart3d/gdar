# Design: Autocorr Beat Detector Mode
**Date:** 2026-04-06
**Status:** Approved — awaiting implementation

---

## Overview

Add `autocorr` as a new option in the TV screensaver Beat Detector segmented button. When selected, two sub-rows appear below the beat detector row (same expand pattern as EKG's Radius/Replication rows) allowing the user to experiment with autocorrelation-driven beat detection and logo scale variants.

---

## Beat Detector Row Change

Add `autocorr` as the 7th segment in `_BeatDetectorSegmentedButton`:

```
Auto · Hybrid · Bass · Mid · Broad · Enhanced · Autocorr
```

Description for `_beatDetectorDescriptions`:
> "Autocorr uses autocorrelation of the audio waveform to estimate tempo. Use the sub-options below to control how it drives beats and logo scale."

Autocorr second-pass is **implicitly forced on** in native when `beatDetectorMode == 'autocorr'` — user does not need to separately enable `beatAutocorrSecondPass`.

---

## Sub-row 1: Beat Variant

Appears when `oilBeatDetectorMode == 'autocorr'`.
Label: **"Autocorr Beat"**

3-way `SegmentedButton<String>`:

| Segment label | Key value | Behaviour |
|---|---|---|
| `BPM` | `bpm` | `beatBpm` always from autocorr; onset (`isBeat`) stays hybrid |
| `Grid` | `grid` | `isBeat` fires when `beatPhase` crosses 0 (metronome grid); BPM from pulse tracker |
| `Both` | `both` | Autocorr BPM + grid-locked `isBeat` |

Default: `'bpm'`

---

## Sub-row 2: Logo Scale Variant

Appears when `oilBeatDetectorMode == 'autocorr'`.
Label: **"Autocorr Logo Scale"**

3-way `SegmentedButton<String>`:

| Segment label | Key value | Behaviour |
|---|---|---|
| `Pulse` | `pulse` | Scale bump fires on autocorr beat grid (replaces energy-spike `beatImpact` bump) |
| `Sine` | `sine` | `scaleSineFreq` auto-locked to autocorr BPM (`bpm / 60.0 Hz`); logo breathes in tempo |
| `Both` | `both` | Grid bump + BPM-locked sine underneath |

Default: `'pulse'`

---

## New Settings Keys

Both are screensaver-only, stored in `settings_provider_screensaver.dart`:

| Key constant | SharedPrefs key | Type | Default |
|---|---|---|---|
| `_autocorrBeatVariantKey` | `oil_autocorr_beat_variant` | `String` | `'bpm'` |
| `_autocorrLogoVariantKey` | `oil_autocorr_logo_variant` | `String` | `'pulse'` |

Exposed on `SettingsProvider` as:
- `String get oilAutocorrBeatVariant`
- `String get oilAutocorrLogoVariant`
- `Future<void> setOilAutocorrBeatVariant(String v)`
- `Future<void> setOilAutocorrLogoVariant(String v)`

---

## Data Flow

### Flutter → Native

`VisualizerAudioReactor.updateConfig()` and `AudioReactor` base interface gain two new optional params:
- `String? autocorrBeatVariant`
- `String? autocorrLogoVariant`

`screensaver_screen.dart` and `tv_screensaver_preview_panel.dart` pass both when pushing config updates (same pattern as `autocorrSecondPass`).

### Native (Kotlin — VisualizerPlugin.kt)

Add `"autocorr"` case to `when (selectedMode)`:

```kotlin
"autocorr" -> {
    // autocorr second pass is forced on regardless of autocorrSecondPass flag
    when (autocorrBeatVariant) {
        "grid", "both" -> DetectorSelection(
            isBeat = /* fire when beatPhase crosses 0 */,
            score = autocorrBpm ?: 0.0,
            threshold = 1.0,
            confidence = if (autocorrBpm != null) 1.0 else 0.0,
            source = "AUTOCORR",
        )
        else -> // "bpm" — keep hybrid onset
            DetectorSelection(
                isBeat = hybridIsBeat,
                score = hybridScore,
                threshold = beatThreshold,
                confidence = hybridConfidence,
                source = "AUTOCORR_BPM",
            )
    }
}
```

For `bpm` and `both` variants, force `useAutocorr = true` when reporting `beatBpm`.

### StealConfig

Add two new fields mirroring the settings:
- `final String autocorrBeatVariant` (default `'bpm'`)
- `final String autocorrLogoVariant` (default `'pulse'`)

Include in `fromMap`, `toMap`, `copyWith`, `==`, `hashCode`.

### Logo Scale (steal_game.dart or steal_background.dart)

When `config.beatDetectorMode == 'autocorr'` (or equivalent flag passed through config):

- **`pulse`**: Apply `beatImpact` scale bump when `energy.isBeat` fires (same as now, but the beat comes from the autocorr grid instead of energy spikes).
- **`sine`**: Override `scaleSineFreq` with `energy.beatBpm / 60.0` each frame when `beatBpm != null`. Enable sine even if `scaleSineEnabled` is false.
- **`both`**: Both of the above.

---

## Files to Touch

| File | Change |
|---|---|
| `tv_screensaver_section_controls.dart` | Add `autocorr` to `_BeatDetectorSegmentedButton._modes/_labels` |
| `tv_screensaver_section.dart` | Add `autocorr` description; add `_buildAutocorrSubRows()` |
| `tv_screensaver_section_audio_build.dart` | Render sub-rows when `autocorr` selected |
| `settings_provider_screensaver.dart` | Add 2 new keys + getters/setters |
| `default_settings.dart` | Add 2 new defaults |
| `audio_reactor.dart` | Add 2 params to `updateConfig()` |
| `visualizer_audio_reactor.dart` | Pass new params through method channel |
| `screensaver_screen.dart` | Read + push new settings |
| `tv_screensaver_preview_panel.dart` | Pass new settings to reactor |
| `steal_config.dart` | Add 2 new fields |
| `steal_game.dart` / `steal_background.dart` | Implement logo scale variants |
| `VisualizerPlugin.kt` (TV + mobile) | Add `autocorr` case; handle beat/BPM variants |
