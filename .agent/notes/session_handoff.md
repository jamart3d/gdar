# Session Handoff — 2026-04-06

## What Was Done

### Design Session — Autocorr Beat Detector Mode

No code was written this session. A full feature design was brainstormed and approved.
Design doc saved to: `docs/superpowers/specs/2026-04-06-autocorr-beat-mode-design.md`

### Summary of Approved Design

Add `Autocorr` as a 7th segment in the Beat Detector row. When selected, two
sub-rows appear (EKG-style expand):

**Sub-row 1 — "Autocorr Beat"** (3-way toggle):
- `BPM` — force autocorr BPM reporting; keep hybrid onset
- `Grid` — fire `isBeat` on autocorr tempo grid (metronome)
- `Both` — autocorr BPM + grid-locked onset

**Sub-row 2 — "Autocorr Logo Scale"** (3-way toggle):
- `Pulse` — scale bump on autocorr beat grid
- `Sine` — `scaleSineFreq` auto-locked to autocorr BPM
- `Both` — grid bump + BPM-locked sine

Key constraint: autocorr second-pass is **implicitly forced on** in native
when `beatDetectorMode == 'autocorr'` — no separate user toggle needed.

## What Is NOT Done / Watch Out For

- No code written yet — implementation plan not started.
- Need to add `autocorrBeatVariant` and `autocorrLogoVariant` to both the
  TV and mobile `VisualizerPlugin.kt` files.
- The `beatDetectorMode` field does not exist in `StealConfig` yet — need
  to add it (or pass the variant flags as separate fields through config).
- Logo scale sine override in `steal_game.dart` / `steal_background.dart`
  needs care: must not conflict with the user's manual `scaleSineEnabled`
  setting when autocorr mode is off.

## Key Files to Touch (from design doc)

| File | Change |
|---|---|
| `tv_screensaver_section_controls.dart` | Add `autocorr` segment |
| `tv_screensaver_section.dart` | Description + sub-row builder |
| `tv_screensaver_section_audio_build.dart` | Render sub-rows |
| `settings_provider_screensaver.dart` | 2 new keys + getters/setters |
| `default_settings.dart` | 2 new defaults |
| `audio_reactor.dart` | 2 new params on `updateConfig()` |
| `visualizer_audio_reactor.dart` | Pass through method channel |
| `screensaver_screen.dart` | Read + push new settings |
| `tv_screensaver_preview_panel.dart` | Pass to reactor |
| `steal_config.dart` | 2 new fields |
| `steal_game.dart` / `steal_background.dart` | Logo scale variants |
| `VisualizerPlugin.kt` (TV + mobile) | `autocorr` case in beat selector |

## Previous Session Context

Previous commit (4f7d983) covered: TV screensaver audio graph scaling,
logo suppression shader fix, VU meter needle/spindle fix, beat debug dot
removal, enhanced detector UI colour-coding. Shader fix still unverified
on device — logo should fully disappear when "Preview: Audio Graph" is ON.
