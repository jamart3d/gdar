# TODO: True Stereo L/R VU Meters via AudioPlaybackCapture

## Status
**Infrastructure and screensaver activation path complete (2026-03-21). Awaiting real-device test.**

Correction: the low-level pipeline was already implemented earlier, and as of
2026-03-21 the TV screensaver now owns a normal activation path for stereo
capture in the graph modes that actually use it.

Core pipeline implemented — see `audio_reactivity_status.md` for full details.
Current VU meter falls back to fake stereo (FFT bands 0–3 → L, 4–7 → R) until
`VisualizerAudioReactor.requestStereoCapture()` is called and the system dialog
approved. Range label shows `ST` when real stereo is active, `LO`/`HI` when fake.

## Why the Visualizer API can't do it

`android.media.audiofx.Visualizer` taps the final output mix as **mono**. There
is no L/R split available at that point in the Android audio pipeline.

## The right approach: AudioPlaybackCapture (API 29+)

`AudioPlaybackCapture` (introduced Android 10 / API 29) lets an app record its
own audio output as raw stereo PCM without requiring `RECORD_AUDIO` permission.
It is the correct mechanism for true stereo waveform and level data.

### What it unlocks
- Real L and R channel levels → true dual VU needle meters
- Stereo waveform → Lissajous/XY scope (L vs R phase display)
- Stereo correlation meter (goniometer-style)
- True stereo oscilloscope

### Implementation outline

1. **Add `AudioPlaybackCaptureConfiguration`** in `MainActivity.kt` / the audio
   setup path, creating an `AudioRecord` configured to capture the app's own
   playback session.

   ```kotlin
   val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
       .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
       .build()

   val audioRecord = AudioRecord.Builder()
       .setAudioPlaybackCaptureConfig(config)
       .setAudioFormat(
           AudioFormat.Builder()
               .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
               .setSampleRate(44100)
               .setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
               .build()
       )
       .setBufferSizeInBytes(bufferSize)
       .build()
   ```

2. **`MediaProjection` is NOT required** if the app uses
   `AudioPlaybackCaptureConfiguration` without screen capture. However, confirm
   this against current Android docs — some versions required it; as of API 29
   intra-app capture should work without the projection permission dialog.

3. **Separate channel data** — interleaved stereo PCM: even samples = L,
   odd samples = R. Downsample each channel independently to ~256 points.

4. **New event channel or extend existing** — either add a second
   `EventChannel` (`shakedown/stereo_events`) or extend the existing
   `shakedown/visualizer_events` payload with `waveformL` / `waveformR` lists
   alongside the existing `waveform` (mono from Visualizer).

5. **`AudioEnergy` extension** — add `waveformL` and `waveformR` fields
   (parallel to existing `waveform`).

6. **`steal_graph.dart` updates**
   - VU `'vu'` mode: switch from FFT-band fake stereo to real L/R RMS levels
   - New `'lissajous'` mode: plot L vs R as X/Y scatter with phosphor decay
   - New `'goniometer'` mode: stereo field meter (rotated 45° Lissajous)

### Scope: gdar_tv only

`AudioPlaybackCapture` code lives in `apps/gdar_tv/android/` alongside
`VisualizerPlugin.kt` — it never touches `gdar_mobile` or `gdar_web`.

The only shared-package change is adding `waveformL`/`waveformR` fields to
`AudioEnergy` in `shakedown_core`. These default to empty lists, so mobile and
web are unaffected. `AudioReactorFactory` is already gated on `isTv`, so the
entire reactor path is dormant on phone.

## Other considerations
- Both `Visualizer` (FFT/beat) and `AudioPlaybackCapture` (stereo PCM) can
  run simultaneously — they tap different points in the pipeline.
- `AudioPlaybackCapture` adds CPU load; gate it behind the same
  `oilEnableAudioReactivity` setting and only activate when mode is `'vu'`,
  `'scope'`, `'lissajous'`, or `'goniometer'`.
- TV hardware (low-end SoCs) may struggle with two concurrent capture paths.
  Measure before shipping.

## Related files
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
- `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
- `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`

---

## 2026-03-21 audit corrections

Short answer: the core true-stereo VU infrastructure has been done, but this
file still mixes completed work with future ideas.

### Implemented now

- `StereoCapture.kt` exists and captures stereo PCM through
  `AudioPlaybackCapture`.
- `MainActivity.kt` owns a `shakedown/stereo` method channel and launches the
  system capture flow.
- `VisualizerPlugin.kt` appends `waveformL` and `waveformR` to the existing
  visualizer payload.
- `AudioEnergy` already has `waveformL` and `waveformR`.
- `visualizer_audio_reactor.dart` already parses `waveformL` and `waveformR`
  and exposes `requestStereoCapture()` / `stopStereoCapture()`.
- `steal_graph.dart` already switches VU mode from fake stereo to real L/R RMS
  when stereo capture is active.
- The fake-stereo fallback remains in place when stereo capture is inactive.

### Not implemented yet

- `lissajous` mode
- `goniometer` mode
- true stereo oscilloscope path
- final real-device validation of the stereo path
- optional broader activation beyond the current screensaver-owned path

### Important corrections

1. The TODO title is now slightly misleading.
   - True stereo VU is no longer just a TODO.
   - The better reading is: infrastructure implemented, awaiting device
     validation and any optional follow-on stereo modes.

2. The note saying `MediaProjection` is not required does not match the current implementation.
   - Current code explicitly requires `MediaProjectionManager` and a permission
     dialog in `MainActivity.kt`.
   - `StereoCapture.start()` takes a `MediaProjection`.
   - So for this codebase, the active implementation path does require the
     projection flow.

3. The event-channel decision has already been made.
   - The code extends the existing `shakedown/visualizer_events` payload.
   - There is no separate stereo event channel.

4. The VU update step is already complete.
   - `vu` mode already consumes real stereo RMS from `waveformL` /
     `waveformR`.
   - Range labels already show `ST` for real stereo and `LO` / `HI` for fake.
   - The panel now also shows digital `SIG` readouts and the active drive
     factor.

5. The "gate it behind mode" recommendation is now partially implemented.
   - `ScreensaverScreen` now auto-requests stereo capture for reactive TV
     screensaver sessions, not just VU-specific views.
   - It stops stereo capture on screensaver dispose or when audio reactivity is
     turned off.
   - That keeps the PCM beat detector available across graph modes while the
     screensaver is active.

6. The stereo path now improves VU and part of the scope path.
   - Standalone `scope` still uses `energy.waveform` from the mono Visualizer
     waveform path.
   - As of 2026-03-21, stereo PCM is now also used by a first-pass PCM beat
     detector when capture is active.
   - That detector now uses raw-buffer mono RMS, fast/slow envelope onset, and
     positive flux computed inside `StereoCapture`.
   - `corner_only` can now render stacked stereo scope lanes from
     `waveformL` / `waveformR` when real stereo capture is active.

7. The feature is now reachable in normal screensaver flow.
   - `ScreensaverScreen` now calls
     `VisualizerAudioReactor.requestStereoCapture()` for reactive TV
     screensaver sessions.
   - It calls `stopStereoCapture()` during cleanup and when audio reactivity is
     disabled.
   - Real-device validation is still needed to confirm permission behavior and
     device compatibility.

### Updated read of this file

The safest interpretation is:

- true stereo VU plumbing is implemented
- permission flow is implemented
- payload transport is implemented
- VU rendering is implemented
- screensaver-owned activation/lifecycle wiring is implemented for reactive TV
  screensaver sessions
- the remaining work is validation and any optional stereo-specific graph modes
