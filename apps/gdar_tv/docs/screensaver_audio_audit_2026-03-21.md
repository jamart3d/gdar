# TV Screensaver Audio Audit

Date: 2026-03-21

Scope:
- `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
- `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`

This is a code audit only. No real-TV runtime validation was performed in this pass.

---

## Executive Summary

The TV screensaver audio pipeline is wired correctly end to end:

`VisualizerPlugin.kt`
-> event channel
-> `VisualizerAudioReactor`
-> `AudioEnergy`
-> `StealGame`
-> `StealBackground` / `StealGraph`

The biggest problem is not the Flutter render path. The biggest problem is that
the native detector and the `beat_debug` visualization have drifted apart:

1. `beat_debug` does not currently show real per-algorithm levels.
2. The on-screen labels do not match the algorithms currently running.
3. The threshold guide shown in the UI does not match the threshold math in
   Kotlin.
4. The detector is still built on peak-normalized band amplitudes, which
   flattens dynamics and weakens onset contrast.
5. Detection is limited by the Android `Visualizer` capture rate, which is
   typically only about 20 Hz on TV hardware.

The result is a system where the screensaver can be audio-reactive, but beat
locking is still too coarse and the debug mode is not trustworthy enough for
calibration.

---

## Current Runtime Path

### Initialization

- `ScreensaverScreen` creates the reactor only on TV Android and only when audio
  reactivity is enabled.
- `ScreensaverScreen` requests microphone permission, pulls the active Android
  audio session ID from `AudioProvider`, starts the reactor, then pushes live
  tuning settings into the native plugin.
- This part looks healthy. The earlier config-ordering bug appears fixed in the
  current code:
  - `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart:114`
  - `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart:162`
  - `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart:163`

### Data Transport

- `VisualizerAudioReactor` parses:
  - 3-band energy
  - 8-band graph data
  - mono waveform
  - stereo waveform
  - beat flags
  - algorithm levels
- This bridge is straightforward and does not appear to be the weak link:
  - `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart:113`

### Screensaver Use Of Audio

- `StealGame` pushes fresh `AudioEnergy` into the graph before component update,
  which avoids a one-frame lag.
- `StealGame.beatPulse` is driven from `energy.isBeat` and decays smoothly.
- `StealBackground` uses both continuous band energy and beat pulse:
  - scale path uses selected band or bass
  - color path uses selected band or treble
  - logo beat boost uses `beatImpact`
- This split is good in principle: continuous energy for motion, discrete beat
  for impact.

Relevant refs:
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart:151`
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart:172`
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart:360`
- `packages/shakedown_core/lib/steal_screensaver/steal_background.dart:346`
- `packages/shakedown_core/lib/steal_screensaver/steal_background.dart:370`

---

## Findings

### P1: `beat_debug` bars are not showing real algorithm levels

At audit time, native code was still sending a diagnostic placeholder:

- `algoLevels = overall * 3.0` for all 6 slots
- every bar therefore received the same continuous level

Refs:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:410`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:419`

Flutter renders those values as if they were real per-algorithm detector ratios:

- `StealGraph` smooths `energy.algoLevels`
- `_renderBeatDebug()` presents them as detector bars with threshold guides

Refs:
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:219`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:235`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:1300`

Impact at audit time:

- `beat_debug` could not answer which algorithm was actually strongest.
- Tuning decisions made from this screen were unsafe.
- Any apparent bar difference was visual smoothing noise, not detector truth.

Status:

- Fixed on 2026-03-21.
- `algoLevels` now report real per-algorithm scores:
  - mean-window variants use `signal / rollingMean`
  - EMA uses `signal / emaBaseline`
- The payload now also exposes richer telemetry:
  - `algoSignals`
  - `algoBaselines`
  - `algoThresholds`
  - `winningAlgoId`

### P1: Algorithm labels have drifted across Kotlin, Dart, and docs

Current Kotlin algorithms are:

- `0`: bass
- `1`: mid
- `2`: broad
- `3`: all
- `4`: ema-on-mid
- `5`: treble

Refs:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:388`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:404`

But the Flutter labels say:

- `BASS`
- `MID`
- `TREB`
- `BROAD`
- `ALL`
- `S-MID`

Ref:
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:107`

At audit time, the `AudioEnergy` comments still described an older mapping:

- `0=NARROW, 1=KICK, 2=FULL, 3=EMA, 4=KICK+, 5=LONG`

That comment drift was fixed on 2026-03-21 so the shared order now matches the
native detector: `BASS`, `MID`, `BROAD`, `ALL`, `EMA`, `TREB`.

At audit time, `longHistory` was still populated natively but not used by any
active detector path. That dead staging path was removed on 2026-03-21.

Impact:

- The debug screen is currently mislabeling what it is showing.
- Code comments no longer describe reality.
- The detector family is harder to evolve because the mapping is duplicated in
  three places and already out of sync.

### P1: Threshold lines in `beat_debug` do not match detector math

The graph comments say:

- yellow line `1.2x` is the default threshold
- red line `1.7x` is the low-sensitivity threshold

Refs:
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:1302`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:1370`

The actual Kotlin formula is:

- `adaptiveMultiplier = 1.2 + (1.0 - beatSensitivity) * 1.0`

Which means:

- `beatSensitivity = 1.0` -> `1.2x`
- `beatSensitivity = 0.5` -> `1.7x`
- `beatSensitivity = 0.0` -> `2.2x`

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:385`

The EMA path is different again:

- `sig1 > midEmaVal * (1.0 + (1.0 - beatSensitivity) * 0.5)`

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:398`

Impact at audit time:

- The threshold lines on screen were misleading.
- The operator could believe the detector was missing beats when the overlay
  was simply showing the wrong threshold.

Status:

- Fixed on 2026-03-21.
- `beat_debug` now derives its guide lines from live `beatSensitivity` and
  labels them `MEAN` and `EMA`.

### P1: Detector still relies on peak-normalized amplitudes, which compresses dynamics

Current native flow:

1. compute raw band magnitudes
2. divide by rolling peak
3. compare normalized signal to rolling mean or EMA

Refs:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:278`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:299`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:318`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:333`

Why this is a problem:

- Peak normalization is useful for rendering bars, but it is not a strong onset
  signal.
- Once the peak tracker settles, loud and quiet sections both trend toward a
  similar normalized range.
- That reduces transient contrast and makes a beat detector depend too heavily
  on tiny relative changes.
- This is especially fragile for live recordings with soft kicks, room noise,
  and drifting mix balance.

### P2: `bassBoost` still contaminates detector input

The calibration rule for this feature family says beat detection should use raw
pre-boost energy, so user gain controls only affect visual magnitude and not
beat frequency.

At audit time, code boosted `rawBass` before detector normalization:

- `rawBass = (rawBass * bassBoost).coerceIn(0.0, 2.0)`

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:282`

That boosted value feeds:

- `normalizedBass`
- `sig0`
- `sig3`
- `sig4`

Refs:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:299`

Status:

- Fixed on 2026-03-21.
- The detector bass path now uses pre-boost energy and its own normalization peak.
- `bassBoost` now changes visible bass magnitude without changing bass detector rate.

Impact:

- Bass-oriented detector variants can change trigger behavior when the user is
  only trying to make visuals feel stronger.
- This also muddies `beat_debug` comparison, because some algorithms are using
  gain-affected input and others are not.

### P2: Capture-rate ceiling limits beat quality on TV

The plugin intentionally uses `Visualizer.getMaxCaptureRate()`:

- usually about `20000 mHz` = `20 Hz`

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:162`

Practical consequence:

- There are only about 10 analysis frames in a 120 BPM quarter-note interval.
- Fast transients are easy to miss or smear across adjacent frames.
- Mean-window detectors become coarse and timing jitter becomes visible in the
  logo pulse.

This is likely the single largest hard platform constraint on the current FFT
path.

### P3: Debug defaults and comments are drifting

Examples:

- `DefaultSettings` comment still describes an older threshold mapping:
  - `packages/shakedown_core/lib/config/default_settings.dart:153`
- `DefaultSettings.oilAudioGraphMode` comment does not list newer graph modes:
  - `packages/shakedown_core/lib/config/default_settings.dart:141`
- `VisualizerPlugin.kt` header comment says primary beat is a kick/sub-bass
  detector, but actual primary is now `MID`:
  - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:25`
  - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:406`

These are not the root cause of bad beat detection, but they do make tuning and
maintenance slower.

### P3: `StealGraph` performance naming looks inverted

Current graph flags:

- `_isFast => performanceLevel >= 2`
- `_isBalanced => performanceLevel == 1`

Ref:
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart:151`

But TV defaults and existing docs describe:

- `0 = Fast`
- `1 = Balanced`
- `2 = High`

Refs:
- `packages/shakedown_core/lib/config/default_settings.dart:95`
- `packages/shakedown_core/lib/config/default_settings.dart:213`

Impact:

- Graph glow/blur quality may currently be assigned to the wrong performance
  tier.
- This is secondary to beat detection, but it is worth cleaning up because it
  affects debug readability and render cost.

---

## Beat Detection Improvement Suggestions

### 1. Fix `beat_debug` first

This is the best first move because it improves observability before changing
the detector itself.

Recommended payload per algorithm:

- `id`
- `label`
- `signal`
- `baseline`
- `threshold`
- `score`
- `fired`
- `refractoryMsRemaining`

At minimum, replace the current placeholder `algoLevels` with real values such
as:

- `signal / baseline`
- `(signal - baseline).coerceAtLeast(0.0)`
- a normalized onset score in `0.0..3.0`

Best shape:

- Stop shipping parallel arrays.
- Send a list of maps or a typed model-equivalent payload.
- Keep one single source of truth for algorithm names and order.

### 2. Decouple render normalization from detection normalization

Use different signals for different jobs:

- Bars, circular EQ, and general motion can continue using normalized and
  smoothed band magnitudes.
- Beat detection should use a less flattened signal:
  - raw log-magnitude energy
  - band-limited envelope
  - positive spectral flux
  - or fast-vs-slow envelope difference

This preserves visual stability without destroying beat contrast.

### 3. Replace rolling-peak onset with a hybrid onset score

Recommended detector for the current music profile:

- low-band envelope for kick/bass movement
- mid-band envelope for snare/guitar transients
- broadband positive flux for general rhythmic onset

Example shape:

```text
lowFast  = ema(lowEnergy,  attackFast)
lowSlow  = ema(lowEnergy,  releaseSlow)
midFast  = ema(midEnergy,  attackFast)
midSlow  = ema(midEnergy,  releaseSlow)
allFlux  = max(0, allLogEnergy - prevAllLogEnergy)

score =
  0.50 * max(0, lowFast - lowSlow) +
  0.30 * max(0, midFast - midSlow) +
  0.20 * allFlux

threshold = median(scoreWindow) + k * mad(scoreWindow)
isBeat = score > threshold && score > floor && refractoryExpired
```

Why this is a better fit:

- low band keeps the pulse anchored
- mid band catches live-recording transients when bass is weak on the chipset
- flux helps with attack timing
- median/MAD is more robust than rolling peak for noisy live material

### 4. Use PCM for beat detection when available

The project already has `StereoCapture` via `AudioPlaybackCapture`.

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt:55`

That is the most promising upgrade path because:

- PCM has much higher temporal fidelity than `Visualizer` FFT callbacks
- you can run a proper envelope follower or a small real FFT window locally
- beat timing will be far less jittery than the 20 Hz `Visualizer` path

Suggested strategy:

- Sum stereo to mono for detector input
- run a lightweight 512 or 1024 sample analysis hop
- keep `Visualizer` for cheap bars if desired
- use PCM detector as the authoritative `isBeat` source when permission is
  granted
- fall back to the current Visualizer detector when PCM capture is unavailable

### 5. Keep user gain controls out of detection

Recommended split:

- `bassBoost`
- `reactivityStrength`
- `beatImpact`

should affect visuals only.

Detection inputs should use:

- raw pre-boost energy
- log-compressed or envelope-shaped values
- stable adaptive thresholds

This preserves predictable tuning and matches the existing calibration rule.

### 6. Add detector confidence, not just `isBeat`

Right now everything collapses to a boolean too early.

Suggested additions:

- `beatScore`
- `beatThreshold`
- `beatConfidence`
- `beatSource` or `winningAlgoId`

That would let the screensaver:

- pulse strongly on high-confidence beats
- pulse softly on weak rhythmic activity
- keep motion alive even when no hard beat is declared

### 7. Consider tempo-aware refractory instead of fixed 200 ms only

Current detector uses:

- `MIN_BEAT_GAP_MS = 200`

Ref:
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt:52`

This is acceptable as a hard safety gate, but not ideal as the only timing
policy.

Better options:

- `120 ms` to `180 ms` for visual pulses
- dynamic refractory based on recent inter-onset intervals
- separate "strong beat" vs "sub-beat" channels

That would reduce missed pulses on faster rhythmic content while still avoiding
machine-gun retriggers.

---

## Suggested Implementation Order

1. Make `beat_debug` honest.
2. Remove label and threshold drift.
3. Stop using boosted bass in detector inputs.
4. Replace `algoLevels` placeholder with real algorithm telemetry.
5. Add a hybrid envelope-plus-flux detector on the existing Visualizer path.
6. Add optional PCM-based beat detection using `StereoCapture`.
7. Tune on real TV hardware with a capture/replay harness.

---

## Low-Risk Immediate Fixes

- Replace fake `algoLevels` with real per-algorithm scores.
- Update `_algoLabels` to match native order exactly.
- Remove stale `AudioEnergy` comments.
- Draw threshold lines from current `beatSensitivity`, not hardcoded values.
- Use pre-boost bass for all detector signals.
- Rename graph performance helpers to match actual tiers.

---

## Larger Improvements

- Add a hybrid detector that combines low-band envelope, mid-band envelope, and
  broadband flux.
- Promote PCM-based detection to the preferred TV path.
- Add a real UI or screensaver-owned activation path for stereo capture, so the
  PCM path is reachable in normal TV use.
- Add lifecycle cleanup for stereo capture so permission-granted sessions do not
  outlive the graph modes that need them.
- Record short real-device detector traces to JSON for replayable tuning.
- Add a "winning algorithm" indicator to `beat_debug` so the screen answers
  which strategy is currently tracking the music best.

---

## Patch TODO

This section is the recommended patch sequence. It is intentionally split into
small steps so observability is fixed before detector behavior changes.

### Phase 0: Cleanup the debug contract

1. Update comments and labels so code, docs, and UI describe the same detector order.
   Files:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
   - `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
   - `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
   - `packages/shakedown_core/lib/config/default_settings.dart`
   Status:
   - Completed 2026-03-21.
   - Detector order is now documented consistently as `BASS`, `MID`, `BROAD`, `ALL`, `EMA`, `TREB`.
2. Remove or repurpose `longHistory` if it is not part of the active detector family.
   File:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
   Status:
   - Completed 2026-03-21.
   - `longHistory` and its unused long-window staging path were removed.
   - No detector behavior changed; active algorithms remain `BASS`, `MID`, `BROAD`, `ALL`, `EMA`, `TREB`.
3. Fix the threshold guide text in `beat_debug` so it reflects the current sensitivity math.
   File:
   - `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
   Status:
   - Completed 2026-03-21.
   - `beat_debug` threshold guides now derive from live `beatSensitivity`.
   - The screen now labels the red line as `MEAN` and the yellow line as `EMA`.

### Phase 1: Make `beat_debug` honest

1. Replace diagnostic `algoLevels = overall * 3.0` with real per-algorithm scores.
   File:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
   Status:
   - Completed 2026-03-21.
   - `algoLevels` now carry real score values for `BASS`, `MID`, `BROAD`, `ALL`, `EMA`, `TREB`.
2. Decide the score definition and keep it consistent.
   Recommended:
   - `score = signal / baseline`, clamped to `0.0..3.0`
   - separate fields for `signal`, `baseline`, and `threshold`
   Status:
   - Completed 2026-03-21.
   - The live contract now uses `score = signal / baseline`, clamped to `0.0..3.0`.
3. Expand the event payload so Flutter receives real detector telemetry.
   Minimum fields:
   - `beatAlgos`
   - `algoLevels`
   Better fields:
   - `algoSignals`
   - `algoBaselines`
   - `algoThresholds`
   - `winningAlgoId`
   Status:
   - Completed 2026-03-21.
   - All listed "better fields" were added to the TV payload.
4. Update the Dart bridge to parse the new payload safely.
   File:
   - `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
   Status:
   - Completed 2026-03-21.
   - The parser now reads `algoSignals`, `algoBaselines`, `algoThresholds`, and `winningAlgoId`.
5. Update `StealGraph` so the bar labels, bar heights, and threshold guides all match the native payload.
   File:
   - `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
   Status:
   - Completed 2026-03-21.
   - `beat_debug` now consumes native threshold ratios when present.
   - The panel also shows the current winning algorithm.

Test coverage note:

- The base Flutter/Flame harness already exists and is not a missing prerequisite.
- Existing automated coverage already includes:
  - `packages/shakedown_core/test/steal_screensaver/steal_game_test.dart`
  - `packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart`
  - `packages/shakedown_core/test/screens/screensaver_screen_test.dart`
  - `packages/shakedown_core/test/visualizer/visualizer_audio_reactor_parsing_test.dart`
- The remaining test work is narrower:
  - add `beat_debug`-specific assertions
  - add parsing checks for richer telemetry fields
  - add regression coverage for threshold-guide math vs `beatSensitivity`

### Phase 2: Decouple visuals from detection

1. Split raw detector signals from display-normalized signals in the Kotlin plugin.
   File:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
   Status:
   - Completed 2026-03-21.
   - The plugin now keeps a separate pre-boost detector bass path and a post-boost visual bass path.
2. Keep these as visual-only controls:
   - `bassBoost`
   - `reactivityStrength`
   - `beatImpact`
   Status:
   - Completed 2026-03-21 for the current implementation path.
   - `bassBoost` is now visual-only in native detection.
   - `reactivityStrength` was already visual-only because it is applied after detector inputs are derived.
   - `beatImpact` remains a Dart-side visual control.
3. Ensure all beat detector inputs use pre-boost energy.
   Status:
   - Completed 2026-03-21 for bass-derived detector inputs.
4. Preserve the current smoothed normalized bands for:
   - corner graph
   - circular graph
   - shader-driven motion

### Phase 3: Implement the hybrid Visualizer-path detector

1. Add low-band, mid-band, and broadband detector signals from raw or log energy.
   File:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
   Status:
   - Completed 2026-03-21.
   - The current hybrid path uses low-band onset, mid-band onset, and positive broadband flux.
2. Add fast and slow envelopes for low and mid bands.
   Suggested outputs:
   - `lowOnset = max(0, lowFast - lowSlow)`
   - `midOnset = max(0, midFast - midSlow)`
   Status:
   - Completed 2026-03-21.
   - Low and mid fast/slow followers now feed onset terms in the hybrid score.
3. Add positive broadband flux.
   Suggested output:
   - `allFlux = max(0, allLogEnergy - prevAllLogEnergy)`
   Status:
   - Completed 2026-03-21.
   - First pass uses positive flux on the current broadband onset signal.
4. Fuse the three cues into one score.
   Suggested weighting:
   - `0.50 * lowOnset`
   - `0.30 * midOnset`
   - `0.20 * allFlux`
   Status:
   - Completed 2026-03-21.
   - Current weighting is `0.45 low + 0.35 mid + 0.20 flux`.
5. Add adaptive thresholding using a rolling robust baseline.
   Preferred:
   - median + MAD
   Acceptable first pass:
   - EMA baseline + floor + refractory
   Status:
   - Completed 2026-03-21 for the first-pass target.
   - The live hybrid detector now compares against the previous EMA-style baseline plus a small floor, then folds the current score into state after the decision.
   - A median/MAD baseline is still optional future work, but the rolling-average baseline is no longer used for final `isBeat`.
6. Export:
   - `beatScore`
   - `beatThreshold`
   - `beatConfidence`
   - `winningAlgoId`
   Status:
   - Completed 2026-03-21.
   - The TV payload now exports `beatScore`, `beatThreshold`, `beatConfidence`, and `winningAlgoId`.
   - `beat_debug` now shows the final hybrid score, threshold, and confidence in its header.
7. Make the final `isBeat` come from the hybrid score, not from a single fixed `MID` rule.
   Status:
   - Completed 2026-03-21.
   - Final `isBeat` now comes from the hybrid onset score.

### Phase 4: Connect the new detector to the screensaver

1. Extend `AudioEnergy` if additional detector fields are needed.
   File:
   - `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
2. Update `StealGame` and `StealBackground` only if confidence-aware pulsing is added.
   Files:
   - `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
   - `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`
3. Keep the current boolean pulse path as a fallback while tuning.

### Phase 5: Optional PCM detector upgrade

1. Reuse `StereoCapture` as the preferred timing source when capture permission is granted.
   Files:
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`
   - `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
2. Add a user-facing ownership path that explicitly starts and stops stereo
   capture from the TV UI or screensaver lifecycle.
   Files:
   - `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
   - `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
   - `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
   Notes:
   - call `requestStereoCapture()` only when a stereo-dependent mode or PCM beat
     path is needed
   - call `stopStereoCapture()` when leaving that mode or shutting down the
     screensaver
3. Sum stereo PCM to mono for detection.
4. Run a lightweight analysis hop on PCM:
   - envelope follower
   - or small-window FFT plus flux
5. Keep `Visualizer` as fallback for:
   - no permission
   - unsupported device path
   - low-end performance fallback
6. Keep optional stereo-only graph modes separate from detector work.
   Examples:
   - Lissajous
   - goniometer
   - true stereo oscilloscope

### Phase 6: Validation and tuning

1. Use `beat_debug` to confirm:
   - bars move independently
   - labels match actual algorithms
   - thresholds track the selected sensitivity
   - a winning algorithm can be identified
2. Keep automated regression coverage current as telemetry evolves.
   Add or extend tests for:
   - `beat_debug` label order
   - `beat_debug` threshold-guide math vs `beatSensitivity`
   - parsing of added telemetry fields such as signals, baselines, and thresholds
3. Test on real TV hardware with at least:
   - kick-heavy studio track
   - live Grateful Dead recording
   - quieter acoustic material
   Suggested quick tuning sequence:
   - Start in `beat_debug` with current defaults and let the detector warm up for 10 to 15 seconds.
   - Use one kick-heavy track first to judge basic lock, missed beats, and double-fires.
   - Switch to a live Dead track to judge chatter, drift, and whether the detector follows vocal/guitar transients instead of the groove.
   - Finish with quieter acoustic material to confirm the floor is not suppressing all useful motion.
   What to watch in `beat_debug`:
   - `SCR` should rise above `THR` cleanly on strong onsets, not hover just under it forever.
   - `CNF` should spike on real hits and spend most non-hit frames below `1.0`.
   - `WIN` should move sensibly between `BASS`, `MID`, `BROAD`, `ALL`, `EMA`, and `TREB`, but final pulse quality matters more than a single winning bar.
   - If bars look active but no beat fires, the floor or threshold is likely too high.
   - If beats machine-gun during dense passages, the floor or refractory is likely too low.
   Adjustment order on hardware:
   - Tune `beatSensitivity` first.
   - Then tune hybrid weight balance or floor constants in Kotlin if sensitivity alone cannot separate missed beats from chatter.
   - Touch `bassBoost` only to judge visual feel, not detector correctness.
4. Verify that changing `bassBoost` changes visual intensity but not beat frequency.
5. Verify that changing `beatSensitivity` changes trigger rate in the expected direction.
6. Verify the stereo activation path end to end:
   - permission prompt appears when expected
   - `ST` labels appear only when real stereo is active
   - fallback returns cleanly to `LO`/`HI` when stereo capture is unavailable or stopped
7. Verify no regressions in:
   - corner graph
   - circular graph
   - VU mode
   - scope mode
   - `corner_only`

### Definition of done for the patch

- `beat_debug` shows real detector telemetry.
- Detector labels and thresholds match native logic exactly.
- Beat pulses are visibly more stable on real TV hardware.
- `bassBoost` no longer changes detection behavior.
- The final `isBeat` comes from either:
  - the hybrid Visualizer-path detector
  - or PCM when available, with Visualizer fallback.
