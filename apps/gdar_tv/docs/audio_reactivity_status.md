# Audio Reactivity — Implementation Status

## Current status (2026-03-20)

Built and ready for real-device testing. Emulator confirmed unreliable for all
audio reactivity work — see notes below.

---

## What was implemented this session

### 1. Beat detection pipeline fix (`VisualizerPlugin.kt`)

- Discovered that missing `@drawable/tv_banner` caused AAPT to fail before
  `compileKotlin` ran — every build since the drawable was removed deployed
  stale Kotlin. All `algoLevels` / `beatAlgos` changes were silently ignored.
- Created `apps/gdar_tv/android/app/src/main/res/drawable/tv_banner.xml`
  (black rectangle placeholder) to unblock resource linking.
- After unblocking, deployed updated beat detection:
  - Replaced bass-focused algorithms with 3-band signals (bass / mid / treble)
    because this TV chipset returns near-zero sub-bass FFT energy.
  - 6 parallel algorithms: BASS, MID (primary `isBeat`), TREB, BROAD, ALL, S-MID.
  - `algoLevels` currently hardcoded to `overall * 3.0` for pipeline confirmation
    — replace with real signal ratios once LEN:6 is confirmed on real TV.

### 2. 8-band silence gate fix (`VisualizerPlugin.kt`)

Corner bar graph went to zero after reinstall. Root cause: per-band gate
`if (rawBand < SILENCE_THRESHOLD)` was too aggressive for narrow FFT bins.
Individual narrow bands (e.g. 1 bin for 0–60 Hz) accumulate less energy than
the broad 3-band buckets (e.g. 5 bins for 0–250 Hz), so they fell below the
0.01 threshold even during loud playback.

Fix: replaced per-band gate with the global silence flag:
```kotlin
// Before (broken for narrow bands):
val normalized = if (rawBand < SILENCE_THRESHOLD) 0.0 else (rawBand / peakBands[b])...

// After (uses 3-band aggregate which has enough bins to be meaningful):
val isSilent = rawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD
val normalized = if (isSilent) 0.0 else (rawBand / peakBands[b])...
```

### 3. Cleartext HTTP fix (emulator only)

Added `android:usesCleartextTraffic="true"` to
`apps/gdar_tv/android/app/src/debug/AndroidManifest.xml` so archive.org
`http://` streams play on the API 36 emulator.

### 4. True stereo VU meters — infrastructure complete

Full pipeline implemented. Awaiting real-device test.

**New files / changes:**
- `StereoCapture.kt` — background `AudioRecord` with
  `AudioPlaybackCaptureConfiguration` (API 29+). Downsamples interleaved
  stereo PCM → `waveformL` / `waveformR` (256 points each) as volatile fields.
  Returns false and skips cleanly on API < 29 or permission denied.
- `MainActivity.kt` — new `shakedown/stereo` method channel. `requestCapture`
  launches `MediaProjectionManager.createScreenCaptureIntent()` dialog.
  `onActivityResult` grants the projection to `StereoCapture`. Passes shared
  `StereoCapture` instance to `VisualizerPlugin`.
- `VisualizerPlugin.kt` — takes `StereoCapture` in constructor; appends
  `waveformL` / `waveformR` to every FFT event payload (empty lists when
  capture not active).
- `AudioEnergy` (`audio_reactor.dart`) — new `waveformL` / `waveformR` fields,
  default `const []`. Backwards-compatible with mobile and web.
- `visualizer_audio_reactor.dart` — parses `waveformL` / `waveformR`. Adds
  `requestStereoCapture()` / `stopStereoCapture()` static methods.
- `steal_graph.dart` — `_updateVuLevels` uses real L/R RMS when
  `waveformL.isNotEmpty`, falls back to FFT-band fake stereo otherwise.
  Range label in VU panel shows `ST` (real stereo) or `LO`/`HI` (fake).

**To activate stereo from Dart:**
```dart
final granted = await VisualizerAudioReactor.requestStereoCapture();
```
One-time system dialog. After grant, `waveformL`/`waveformR` flow on every
FFT frame and VU meters switch automatically to real stereo.

---

## Emulator — known limitations

**The Android Visualizer API does not work on emulators.**

- `Visualizer(0)` taps the hardware audio output mix. Emulators have no real
  audio hardware — `isAvailable()` returns false.
- `AudioReactorFactory` returns `null` when the Visualizer is unavailable.
- Result: all `AudioEnergy` values stay at `AudioEnergy.zero()` —
  overall = 0%, bands all zero, `algoLevels` empty, `beatAlgos` empty.

**Corner bar graph regression on emulator (2026-03-20):**

The corner bar graph was briefly showing activity on the emulator in earlier
sessions, then went to zero after a clean reinstall. This is consistent with
the Visualizer not being available — the graph was never truly driven by real
FFT data on the emulator; it may have shown residual smoothed state from a
prior session or a quirk of the emulator's audio subsystem.

After the 8-band silence gate fix and a fresh install, the emulator correctly
shows all zeros (no Visualizer = no data). This is expected behaviour, not a
regression.

**Do not use the emulator to validate audio reactivity.** All testing for
beat detection, bar graph, VU meters, and stereo must be done on real TV
hardware.

---

## Next steps (real TV)

1. Deploy to real Google TV 2020 via ADB / `flutter run`.
2. Confirm corner bars animate → 8-band silence gate fix working.
3. Confirm `BEAT DEBUG` title shows `LEN:6` → Kotlin `algoLevels` pipeline
   reaches Flutter on real hardware.
4. If `LEN:6` confirmed, replace hardcoded `overall * 3.0` in `algoLevels`
   with real algorithm signal ratios to find which tracks rhythm best.
5. Test stereo VU:
   - Navigate to VU mode.
   - Call `VisualizerAudioReactor.requestStereoCapture()` — approve dialog.
   - VU range label changes from `LO`/`HI` → `ST`.
   - Verify L and R needles move independently during stereo content.
   - If TV 2020 SoC struggles (CPU spike, choppy FFT), disable via
     `stopStereoCapture()` and keep fake-stereo fallback.

---

## 2026-03-21 audit corrections

This document is still useful as a session log, but a few beat-detection notes
have drifted from the current code and should not be treated as the final source
of truth.

### What is still accurate

- The general architecture description is accurate:
  - native `VisualizerPlugin.kt`
  - Dart bridge via `visualizer_audio_reactor.dart`
  - graph and screensaver consumption on the Flutter side
- The 8-band silence-gate fix appears accurately described.
- The emulator warning remains accurate: do not use the emulator to validate TV
  audio reactivity.
- The stereo VU infrastructure section is accurate as written:
  - `StereoCapture.kt`
  - `MainActivity.kt`
  - `VisualizerPlugin.kt`
  - `visualizer_audio_reactor.dart`
  - `steal_graph.dart`

### Corrections / caveats

1. `beat_debug` is still diagnostic, not trustworthy enough for algorithm tuning.
   - `algoLevels` are currently hardcoded to `overall * 3.0` in
     `VisualizerPlugin.kt`.
   - That means `LEN:6` only proves the payload reaches Flutter.
   - It does not prove that the six bars represent real per-algorithm strength.

2. The algorithm labels in docs and Flutter no longer match the native detector order exactly.
   - This document lists: `BASS, MID, TREB, BROAD, ALL, S-MID`
   - Current native code is closer to:
     - `0 BASS`
     - `1 MID`
     - `2 BROAD`
     - `3 ALL`
     - `4 EMA`
     - `5 TREB`
   - Flutter `beat_debug` labels are also drifted, so the current screen can be
     misleading until labels and payload are aligned.

3. The native detector is still built on peak-normalized amplitudes.
   - That is acceptable for graph rendering.
   - It is weaker for actual beat onset detection, especially on live material.
   - So the phrase "updated beat detection" is true, but it should not be read
     as "production-quality beat detection".

4. `bassBoost` still affects detector inputs in the current Kotlin path.
   - This means user gain controls can still influence beat behavior, not just
     visual magnitude.
   - That should be corrected before using detector comparisons as a tuning
     reference.

5. The true primary beat path is `MID`, not the older kick/sub-bass description.
   - This matters because some comments in code still describe an older
     bass-first model.

### Updated reading of the status

The safest interpretation is:

- audio reactivity plumbing is implemented
- stereo VU plumbing is implemented
- emulator is not valid for verification
- beat detection is present and wired through
- `beat_debug` currently confirms payload connectivity more than detector quality
- the next priority is to make `beat_debug` honest before tuning detector logic

### Updated next-step priority

Before using `beat_debug` to decide which beat method is best:

1. replace placeholder `algoLevels` with real per-algorithm telemetry
2. align algorithm names across Kotlin, Dart, and docs
3. ensure thresholds shown in Flutter match native sensitivity math
4. then tune detector behavior on real TV hardware
