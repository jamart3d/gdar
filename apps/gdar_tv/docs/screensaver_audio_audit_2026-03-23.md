# TV Screensaver Audio Audit

Date: 2026-03-23

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

This pass combines a code audit with the runtime evidence gathered during the
current tuning session on emulator and hardware.

---

## Executive Summary

The TV screensaver audio stack is in much better shape than it was on
2026-03-21.

What is now clearly working:

- the TV screensaver timeout path is valid in the real `gdar_tv` shell
- the native Visualizer detector is wired cleanly into Flutter
- `beat_debug` is now mostly honest and much more useful for tuning
- the Android `Enhanced`/PCM permission and foreground-service path no longer
  crashes
- the debug overlay now exposes the real native audio session id and PCM health
  telemetry

What is still not where it needs to be:

1. `Enhanced` capture is often alive at the Android/session level but still not
   producing usable PCM analysis on tested paths, so final beat source stays
   `HYBRID`.
2. The `Auto` detector description and actual behavior have drifted apart.
3. The app-session lifetime of `Enhanced` is now workable, but it creates a
   real product decision: the Android capture indicator can remain visible after
   leaving the screensaver.
4. A few comments and labels still describe older behavior.

So the center of gravity has shifted. The biggest problem is no longer "beat
debug is lying" or "Enhanced crashes." The biggest remaining problem is:

`PCM capture can start successfully but still fail to contribute real beat data.`

---

## What Changed Since 2026-03-21

The following items from the previous audit are effectively improved or closed:

- `beat_debug` now uses real per-algorithm scores and richer telemetry rather
  than placeholder bars.
- `beat_debug` now shows:
  - `SID`
  - final source
  - score / threshold / confidence
  - BPM / IBI / phase-grid tracking fields
  - winning algorithm
  - PCM status fields
- native payload now reports the real current audio session id instead of
  relying on a stale Dart-side snapshot
- `Enhanced` capture setup now uses a foreground service and no longer crashes
  on modern Android when permission is granted
- screensaver-level `Enhanced` prompting is limited to explicit `pcm`
  selection
- `Enhanced` capture is now kept alive across screensaver route disposal for the
  life of the app session, which should reduce repeated permission prompts

Recent verification from this session:

- `flutter test packages/shakedown_core/test/screens/screensaver_screen_test.dart`
  passed
- `.\gradlew.bat :app:compileDebugKotlin` in `apps/gdar_tv/android` passed

Known tooling issue in this environment:

- `dart format` / `dart analyze` are still blocked by access errors creating
  `C:\Users\jeff\AppData\Roaming\.dart-tool`

---

## Current Runtime Picture

### Visualizer / Hybrid Path

The normal TV path is healthy.

`VisualizerPlugin.kt`
-> EventChannel payload
-> `VisualizerAudioReactor`
-> `AudioEnergy`
-> `StealGame`
-> `StealBackground` / `StealGraph`

The hybrid detector is live, the screensaver pulses, and `beat_debug` now
shows enough truth to tune with confidence.

### Enhanced / PCM Path

The Android permission and foreground-service path is now healthy enough to
start without crashing:

- system prompt appears
- Android capture indicator appears
- foreground service runs

But on tested paths, logs still showed:

- `pcmBase=0.000`
- `pcmFloor=0.000`
- `pcmLvl=0.000`
- `pcmOn=0.000`
- `pcmFx=0.000`
- final `SRC:HYBRID`

That means the app can be in this state:

- `Enhanced` capture session is active
- native visualizer session is valid
- hybrid detector is working
- PCM detector is still contributing nothing useful

This is the most important open issue.

---

## Findings

### P1: PCM capture can be active without producing usable detector input

This is now the main blocker.

Evidence gathered during this session:

- hardware/emulator logs showed all PCM analysis values stuck at zero while
  visualizer-side values were active
- screenshots showed Android capture indicator present while `beat_debug`
  still reported `SRC:HYBRID`
- the new native state model supports the distinction between:
  - capture active
  - capture fresh
  - analysis frame count
  - PCM age

What this means:

- the permission/service lifecycle is no longer the core problem
- the remaining issue is at the playback-capture / PCM-analysis layer
- `StereoCapture.start()` can succeed without yielding meaningful ongoing
  analysis

Likely causes:

- device/emulator AudioPlaybackCapture compatibility
- silent `AudioRecord` reads
- playback usage/session mismatch for the current `just_audio` / audio-service
  path
- capture warming too slowly or staling between reads

Why this matters:

- `Enhanced` is currently stable but may not be functionally better than
  `HYBRID`
- users can see the Android capture indicator without actually benefiting from
  PCM timing

### P1: `Auto` detector behavior and UI copy were out of sync

This is the most important code/UX drift found in this audit.

Previous user-facing description said:

- `Auto picks the best available source. It uses Enhanced Audio Capture when available, otherwise Hybrid.`

But current screensaver ownership code only requests `MediaProjection` when:

- `settings.oilBeatDetectorMode == 'pcm'`

So on a cold app start:

- `Auto` does not request capture
- therefore PCM is not activated by `ScreensaverScreen`
- therefore `Auto` behaves like `Hybrid` unless stereo capture is already
  active from an earlier explicit `Enhanced` session

This was not just wording drift. It changed product behavior.

Recommendation:

- either change the `Auto` description to match reality
- or explicitly define `Auto` as "use PCM only if capture is already active"

Given the product direction from this session, the safer fix is probably:

- keep permission requests explicit to `Enhanced`
- rewrite `Auto` copy to describe that accurately

Status:

- Fixed on 2026-03-23 at the settings/UI contract level.
- `Auto` now explains that it stays on `Hybrid` by default and only uses PCM
  when Enhanced capture is already active in the current app session.
- The settings panel also explicitly says `Auto` will not start Android capture
  by itself.
- Runtime behavior remains intentionally unchanged: only explicit `Enhanced`
  selection requests `MediaProjection`.

### P2: App-session `Enhanced` lifetime is now workable, but it is a product choice

The previous behavior asked for permission again on every screensaver open
because capture was torn down on route disposal.

Current behavior:

- screensaver disposal does not stop stereo capture
- `MainActivity.onDestroy()` stops `StereoCapture` and the foreground service

This is likely the right engineering change for reduced prompt fatigue, but it
has a real UX tradeoff:

- the Android capture indicator can remain visible after leaving the
  screensaver

This is not a bug by itself. It is a behavior choice that should be considered
intentional and documented.

### P2: Screensaver timeout no longer looks like a fundamental app bug

The current session strongly suggests the timeout problem is not a general
monorepo/screensaver routing failure:

- it works in the real `gdar_tv` shell on the tablet emulator
- manual launch works
- timeout launch works in emulator when testing the actual TV app shell

So the remaining timeout risk is more likely one of:

- hardware-specific phantom activity resets
- hardware startup/route differences
- release/device conditions not reproduced on emulator

This reduces the urgency of app-wide timeout surgery. The next move there
should be targeted hardware logging, not broad refactoring.

### P3: `beat_debug` is much better, but still visually dense

This is improved, not solved.

Recent work stabilized:

- telemetry rows
- fixed-ish columns
- final meter separation
- winning algorithm display
- session / source / threshold / confidence visibility

But the mode is still dense enough that:

- long metadata can crowd the header
- small label drift is immediately visible
- it remains a diagnostics screen, not a polished long-session graph mode

This is acceptable for now because observability is much improved, but it
should stay classified as a diagnostics-first UI.

### P3: Some comments and labels still lag current reality

A few examples still worth cleaning up:

- `AudioEnergy.beatSource` comment says final source is typically `VIS` or
  `PCM`, but the current native source values are things like `HYBRID`,
  `BASS`, `MID`, `BROAD`, and `PCM`
- some older detector commentary in `VisualizerPlugin.kt` still frames the
  system as primarily peak-normalized-band detection, while the live final path
  is now hybrid onset plus optional PCM
- `StealGraph` performance helper naming (`_isFast`) still looks inverted
  relative to the documented performance tiers

These are not the critical blockers anymore, but they still slow tuning and
onboarding.

---

## Status Against The 2026-03-21 Audit

### Clearly Improved

- honest per-algorithm `beat_debug` bars
- richer native telemetry contract
- real native session id on screen
- hybrid final detector path
- pre-boost detector bass split
- PCM path ownership in screensaver lifecycle
- Android foreground-service compliance for `MediaProjection`

### Still Open

- PCM analysis often not producing useful data after capture starts
- `Auto` detector copy vs behavior mismatch
- final UX decision for app-session `Enhanced` lifetime
- residual docs/comment drift
- targeted hardware timeout investigation

### No Longer The Main Concern

- fake placeholder `beat_debug` bars
- crashing `Enhanced` permission path
- "screensaver timeout is globally broken in TV app"

---

## Recommended Next Steps

### 1. Fix the `Auto` / `Enhanced` contract first

This is the cleanest next patch because it resolves a real user-facing mismatch
without touching detector quality yet.

Recommended options:

- update `Auto` copy to say it uses PCM only when already active
- keep permission requests exclusive to explicit `Enhanced`

Do not silently reintroduce automatic prompts through `Auto` unless that is a
deliberate product decision.

### 2. Debug why active PCM capture is not producing useful analysis

This is the highest-value technical investigation now.

Suggested short path:

1. Validate the new PCM debug line on real hardware:
   - `PCM:OFF`
   - `PCM:STALE`
   - `PCM:HOT`
   - frame count
   - age
2. Add temporary native logs for:
   - `AudioRecord.read()` counts
   - first non-zero mono RMS
   - capture stale transitions
3. Confirm whether tested hardware is delivering:
   - silent reads
   - stale analysis
   - or fresh PCM that still loses selection

Definition of progress here:

- `Enhanced` should eventually show `SRC:PCM` on at least one supported target

### 3. Decide and document the intended `Enhanced` lifetime UX

Current implementation keeps capture alive across screensaver closes for the
life of the app session.

That is probably correct for reducing prompt fatigue, but the product should
explicitly accept one of these:

- keep capture alive until app exit
- add a user-visible "release enhanced capture" path
- or stop on app background if the persistent indicator is too surprising

### 4. Use targeted logging on real hardware for timeout issues

Since emulator timeout now works, the right move is not broad timeout rewiring.

Use the existing tracing to determine whether hardware is:

- never arming the timer
- constantly resetting it
- or firing the timeout but failing to navigate

### 5. Clean the remaining comment / label drift

Low risk, worthwhile cleanup:

- `AudioEnergy.beatSource` comment
- `Auto` and `Enhanced` settings text
- any stale native detector header comments
- `StealGraph` performance helper naming

---

## Suggested Implementation Order

1. Fix `Auto` / `Enhanced` wording and semantics.
2. Validate the new PCM debug status line on real hardware.
3. Instrument `StereoCapture` read health until one device reaches real
   `SRC:PCM`.
4. Decide final `Enhanced` capture lifetime UX.
5. Run targeted timeout logging only on real hardware if timeout still fails.
6. Clean remaining docs/comments once the behavior contract is settled.

---

## Bottom Line

The project is no longer blocked by broken screensaver plumbing or a dishonest
debug overlay.

The current state is:

- `HYBRID` path: viable and debuggable
- `Enhanced` startup path: stable
- `Enhanced` detector value: still unproven on tested targets

So the next phase should stop being broad architecture work and become focused
compatibility/tuning work around real PCM analysis and clear mode semantics.
