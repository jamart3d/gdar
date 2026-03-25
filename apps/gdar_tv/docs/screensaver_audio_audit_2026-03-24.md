# TV Screensaver Audio Audit

Date: 2026-03-24

Previous audit: `screensaver_audio_audit_2026-03-23.md`

Scope:
- `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section.dart`
- `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
- `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`
- `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MainActivity.kt`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MediaProjectionForegroundService.kt`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
- `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`

---

## Executive Summary

The TV screensaver audio stack is stable. All 33 scoped tests pass, static
analysis is clean, and every finding from the 2026-03-23 audit has either been
resolved or remains intentionally deferred.

No new regressions found. No code drift detected between documented behavior
and implementation.

**Overall status: green.**

---

## Verification Results

### Static Analysis

```
dart analyze (7 scoped Dart files): No issues found
```

### Test Results

```
33/33 passed (0 failures, 0 skipped)
```

| Test file | Tests | Status |
|---|---|---|
| `screensaver_screen_test.dart` | 12 | PASS |
| `screensaver_exit_test.dart` | 3 | PASS |
| `visualizer_audio_reactor_parsing_test.dart` | 11 | PASS |
| `steal_game_test.dart` | 2 | PASS |
| `steal_graph_test.dart` | 3 | PASS |
| `tv_screensaver_section_test.dart` | 2 | PASS |

---

## Status of 2026-03-23 Findings

### P1: PCM capture active without producing usable detector input — STILL OPEN

No code changes since last audit. This remains the primary open technical
investigation.

Current state unchanged:
- Permission/service lifecycle is healthy
- `StereoCapture.start()` can succeed without yielding meaningful analysis
- All PCM debug telemetry fields are wired and available for hardware diagnosis
- `VisualizerPlugin.kt` correctly gates PCM beat scoring behind warmup
  (analysisFrames >= 12, ~600ms at 20 Hz) and freshness (age <= 250ms)

Next step remains: targeted hardware logging on a device that supports
AudioPlaybackCapture to distinguish silent reads from stale analysis from
capture-session mismatches.

### P1: `Auto` detector behavior and UI copy out of sync — CLOSED

Fixed in the 2026-03-23 session and confirmed stable today.

- `tv_screensaver_section.dart` lines 30–31: Auto description correctly states
  it stays on Hybrid by default and only uses PCM when Enhanced capture is
  already active.
- `screensaver_screen.dart` lines 146–159: PCM capture gating is exclusive to
  `mode == 'pcm'`. Auto does not request MediaProjection.
- `VisualizerPlugin.kt` lines 722–739: Auto routing prefers PCM when warmed up
  and signaling, falls back to Hybrid otherwise. Matches UI copy.
- Test `auto mode explains that it stays hybrid unless capture is already
  active` passes.

### P2: App-session Enhanced lifetime — ACKNOWLEDGED, INTENTIONAL

Current behavior is unchanged and intentional:
- Screensaver dispose does not stop stereo capture
- `MainActivity.onDestroy()` stops capture and foreground service
- Android capture indicator may remain visible after leaving screensaver

This is a documented product choice, not a bug.

### P2: Screensaver timeout — NO LONGER A CODE CONCERN

Previous audit downgraded this to hardware-specific investigation. No code
changes needed. Emulator timeout works correctly in the real `gdar_tv` shell.

### P3: `beat_debug` visual density — UNCHANGED, ACCEPTABLE

Diagnostics-first UI. No regressions. All 6 algorithm slots render correctly
with proper bounds checking and time-corrected smoothing.

### P3: Comment/label drift — MOSTLY CLEAN

Reviewed all scoped files. No TODO/FIXME/HACK comments found anywhere in scope.

One minor item from previous audit is still technically present:
- `AudioEnergy.beatSource` comment at `audio_reactor.dart` could list the full
  set of current source values (HYBRID, BASS, MID, BROAD, PCM) but this is
  cosmetic.

All other previously-flagged comment drift has been addressed or was not
reproducible in the current code.

---

## File-by-File Review

### screensaver_screen.dart (554 lines)

Audio reactor initialization, stereo capture lifecycle, session-ID retry loop.

- PCM capture gating correctly exclusive to `mode == 'pcm'` (line 159)
- Session retry: up to 10 attempts, 2s intervals (lines 281–374)
- Config sync deduplicates via `_lastPushed*` fields (lines 114–144)
- Dispose preserves stereo capture across screensaver relaunches (lines 429–432)
- No drift from documented behavior

### tv_screensaver_section.dart (~800 lines)

Beat detector mode selector, inactivity timeout, visual settings.

- Auto/Enhanced/Bass mode descriptions are accurate and tested
- Graph mode visibility correctly gates EKG controls
- No drift from documented behavior

### audio_reactor.dart (203 lines)

Immutable `AudioEnergy` data class and `AudioReactor` interface.

- All 6 beat algorithm fields present (beatAlgos, algoLevels, algoSignals,
  algoBaselines, algoThresholds, winningAlgoId)
- PCM debug state fields present (debugPcmActive, debugPcmFresh,
  debugPcmAnalysisFrames, debugPcmAgeMs)
- waveformL/R documented as TV-only when AudioPlaybackCapture is active
- No drift

### visualizer_audio_reactor.dart (321 lines)

Dart bridge to Android Visualizer API via MethodChannel/EventChannel.

- `updateConfig` uses Dart 3 null-aware element syntax (`?value` in map
  literals, lines 69–73) — valid and correct
- Event parsing handles all 30+ fields from native data map
- Stereo PCM L/R clamped to -1.0..1.0
- winningAlgoId validated (kept only if >= 0)
- Static stereo capture control methods (requestStereoCapture,
  stopStereoCapture) properly wired
- No drift

### steal_game.dart (386 lines)

Flame game loop driving the screensaver visualizer.

- Audio reactor subscription and energy dispatch working
- Beat pulse: smooth exponential attack (14.0 * dt) and decay (pow(0.04, dt))
- Palette cycling and Woodstock easter egg intact
- Trail position ring buffer (48 points)
- No drift

### steal_background.dart (~500 lines)

Logo motion, color cycling, shader uniform driver.

- Lissajous curve path with random phase/frequency nudges
- beat_debug mode correctly constrains logo to avoid debug panel
- Shader uniform order documented and correct (flowSpeed, filmGrain,
  pulseIntensity, heatDrift, logoScale with beatBoost)
- Performance mode detection reads config.performanceLevel
- No drift

### steal_graph.dart (~800 lines)

Audio visualization overlays: corner bars, circular, EKG, VU meter, beat_debug.

- beat_debug: 6 algorithm scores with flash decay and time-corrected level
  smoothing (12.0 * dt)
- VU meter: correctly distinguishes real stereo (waveformL/R from
  AudioPlaybackCapture, 2.5x boost) from fake stereo (FFT band split)
- EKG: guitar-range extraction from bands 2–4 (~250–2000 Hz)
- Corner mode: 9 bars (8 FFT + beat indicator)
- No drift

### MainActivity.kt (172 lines)

Activity entry point, channel orchestration, stereo permission flow.

- requestCapture fast-paths if already active
- MediaProjection → foreground service → StereoCapture.start() pipeline intact
- onDestroy stops stereo capture and foreground service
- SecurityException catch for API 29+
- No drift

### MediaProjectionForegroundService.kt (124 lines)

Foreground service for AudioPlaybackCapture compliance.

- runWhenReady / markForegroundReady callback sequencing correct
- Notification channel: "enhanced_audio_capture"
- FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION for API 29+
- No drift

### VisualizerPlugin.kt (~900 lines)

Native beat detector orchestrator. The most complex file in scope.

- 8-band frequency decomposition from FFT
- 6 parallel beat algorithms: BASS(0), MID(1), BROAD(2), ALL(3), EMA(4),
  TREB(5) — each with own cooldown (200ms MIN_BEAT_GAP_MS)
- Hybrid final: 45% lowOnset + 35% midOnset + 20% broadFlux
- PCM onset: 70% monoOnset + 30% monoFlux, gated by warmup (12 frames) and
  freshness (250ms)
- Auto routing: prefers PCM when warmed and signaling, falls back to Hybrid
- Zero-FFT watchdog: falls back to session 0 after ~2s silence
  (ZERO_FRAME_THRESHOLD=40)
- Beat grid tracking: IBI history of 8, jitter ratio threshold 0.18, outputs
  BPM/IBI/phase/nextBeat
- Full beat_debug telemetry: signals, baselines, thresholds, scores, levels for
  all 6 algorithms
- No drift from documented behavior

### StereoCapture.kt (223 lines)

AudioPlaybackCapture → PCM analysis pipeline.

- API 29+ gating
- Interleaved stereo → 256-point L/R waveforms
- Mono RMS, fast/slow envelope followers (half-lives ~0.65s / ~3.3s at 20 Hz)
- Onset = max(0, fast - slow), Flux = max(0, level - prevLevel)
- All state fields @Volatile for lock-free access from VisualizerPlugin
- No drift

---

## Test Coverage Gaps (Unchanged from Previous Audit)

These are known gaps, not regressions:

- **Audio reactor lifecycle:** No unit tests for VisualizerAudioReactor
  creation, start, or disposal
- **Permission flow:** Mocked in screensaver_screen_test but no direct test of
  microphone permission request path
- **Inactivity timer:** Zero test coverage for screensaver timeout trigger
- **StealBackground / StealBanner:** No dedicated test files
- **Song hint catalog:** Error handling for catalog load failure untested
- **Woodstock easter egg:** Timing logic untested

None of these gaps are new or represent regression risk.

---

## Recommended Next Steps (Updated)

### 1. Debug PCM capture on real hardware (P1, unchanged)

This is still the highest-value investigation. Use the existing PCM debug
telemetry (PCM:OFF/STALE/HOT, frame count, age) on a device with confirmed
AudioPlaybackCapture support. Add temporary native logs for AudioRecord.read()
counts and first non-zero mono RMS.

### 2. Document Enhanced lifetime UX decision (P2, unchanged)

Current app-session capture lifetime is working but should be explicitly
documented as intentional. Consider whether a "release enhanced capture" UI
path is needed.

### 3. Clean AudioEnergy.beatSource comment (P3, minor)

Update the comment to list all current source values: HYBRID, BASS, MID,
BROAD, PCM.

### 4. Consider adding reactor lifecycle tests (P3, nice-to-have)

The audio reactor lifecycle is currently untested at the unit level. A basic
test for create/start/dispose would reduce regression risk for future changes.

---

## Bottom Line

No regressions since 2026-03-23. The stack is stable, all tests pass, analysis
is clean, and documented behavior matches implementation across all 11 scoped
files.

The only open P1 is the PCM capture producing zero analysis on tested devices —
this is a hardware/compatibility investigation, not a code bug.
