# TODO: True Stereo L/R VU Meters via AudioPlaybackCapture

## Status
**Infrastructure complete (2026-03-20). Awaiting real-device test.**

Correction: the low-level pipeline is implemented, but a normal user-facing
activation path does not appear to be wired yet. `requestStereoCapture()` and
`stopStereoCapture()` exist in the reactor, but they are not currently invoked
from the TV UI or screensaver lifecycle.

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
- a user-facing activation path that actually calls
  `VisualizerAudioReactor.requestStereoCapture()`
- lifecycle cleanup wiring that calls `stopStereoCapture()` when stereo capture
  should end
- automatic mode-based activation of stereo capture
- final real-device validation of the stereo path

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

5. The "gate it behind mode" recommendation is not how the current code works.
   - Stereo capture is started manually by calling
     `VisualizerAudioReactor.requestStereoCapture()`.
   - It is not currently auto-started when entering `vu` or `scope`.

6. The stereo path currently improves VU only.
   - Scope still uses `energy.waveform` from the mono Visualizer waveform path.
   - Stereo PCM is not yet used for scope rendering or beat detection.

7. The feature is implemented at the plumbing layer, but may not yet be
   reachable in normal app flow.
   - A code search in the app layer shows the static methods
     `VisualizerAudioReactor.requestStereoCapture()` and
     `VisualizerAudioReactor.stopStereoCapture()`, but no current call sites.
   - That means true stereo VU support exists, but may still require a manual
     developer-triggered path until the UI or screensaver owns the capture
     lifecycle.

### Updated read of this file

The safest interpretation is:

- true stereo VU plumbing is implemented
- permission flow is implemented
- payload transport is implemented
- VU rendering is implemented
- the remaining work is UI/lifecycle activation, validation, and any optional
  stereo-specific graph modes
