# Implementation Plan - Hybrid Web Audio Engine Fixes (2026-03-09)

Address gaps in the Hybrid Web Audio orchestrator to ensure reliable background playback and robust recovery from browser-enforced audio suspension.

## Proposed Changes

### [Web Orchestrator]

#### [MODIFY] [hybrid_audio_engine.js](file:///c:/Users/jeff/StudioProjects/gdar/web/hybrid_audio_engine.js)

- **Hidden Startup Guard**: Update `syncState(index, position, shouldPlay)` to call `_applyHiddenSurvivalStrategy()` immediately if `document.visibilityState === 'hidden'`. This ensures heartbeats are active *before* the underlying engines are primed.
- **Background Handoff**: Update the `visibilitychange` listener. If switching to `hidden` while `_activeEngine === _fgEngine` (Web Audio) and `_playing` is true:
    - Set `_instantHandoffPending = true`.
    - Call `_attemptHandoff(_currentIndex, true)` to switch to the HTML5 engine before the OS suspends the Web Audio context.
- **Suspension Escape Hatch**: Update `_forwardState`. If `state.processingState === 'suspended_by_os'` and `_playing` is true, call `_executeFailureHandoff()` to immediately swap to HTML5. This provides a secondary recovery path if the proactive handoff failed.
- **Survival Reassert**: Update `setHybridBackgroundMode(mode)` to call `_applyHiddenSurvivalStrategy()` if `document.visibilityState === 'hidden'`. This ensures new background strategies (e.g. switching from 'none' to 'video') are applied immediately even if the tab is already hidden.

---

### [Dart Services]

#### [MODIFY] [gapless_player_web.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/services/gapless_player/gapless_player_web.dart)

- **Mapping Improvement**: Update `_mapProcessingState` to ensure `suspended_by_os` is handled correctly if it ever needs to be bubbled up differently (it currently maps to `ProcessingState.idle` but also triggers a notification in `AudioProvider`). No breaking changes needed, just checking for alignment.

---

## Verification Plan

### Automated Tests
- Run existing audio provider regression tests to ensure no regressions in playback logic:
  `flutter test test/services/web_gapless_adapter_test.dart`
  `flutter test test/providers/audio_provider_regression_test.dart`

### Manual Verification
- **Background Survival**: Start playback in Hybrid mode on Web/PWA. Hide the tab/lock device. Verify playback continues seamlessly (via logs or actual audio).
- **Handoff Verification**: While playing in foreground (Web Audio), hide the tab. Verify the console logs show `[hybrid] Tab hidden. backgroundMode: ...` followed by an immediate handoff to HTML5.
- **Suspension Recovery**: Manually trigger a Web Audio suspension (if possible via browser dev tools) or simulate it. Verify the engine swaps to HTML5 automatically.
- **Live Settings Update**: Change "Hidden Session Preset" while the app is hidden but playing. Verify the new background strategy (e.g. video heartbeat) is applied without a reload.
