# Implementation Plan: Hybrid Audio Engine Refinement

This plan addresses the hybrid audio engine's handoff "stickiness" and the missing `LG` (Last Gap) chip reports identified in the [Web Audio Issue Report](file:///c:/Users/jeff/StudioProjects/gdar/reports/web_audio_issue_report.md).

## User Review Required

> [!IMPORTANT]
> This plan modifies core JS audio orchestrator logic. While primarily non-destructive, it changes the timing of `handoffInProgress` state reporting which affects UI labels.

> [!NOTE]
> The `LG` chip visibility change in Dart will cause `0.0ms` gaps to be displayed instead of being hidden. This is intended to signal a "perfect" gapless transition.

## Proposed Changes

### Web UI (JS Orchestrator)

#### [MODIFY] [hybrid_audio_engine.js](file:///c:/Users/jeff/StudioProjects/gdar/apps/gdar_web/web/hybrid_audio_engine.js)
- **Fix Handoff Race**: Reset `_handoffInProgress = false` **before** calling `_swapEngine` and broadcasting the completion in `_executeForegroundRestore`. This ensures the UI reflects `(WA)` immediately.
- **LG Persistence**: Prevent clearing `_lastGapMs` on `pause()` if a track transition just occurred.
- **State Forwarding**: Update `_forwardState` to merge the sub-engine's `lastGapMs` more reliably into the orchestrator state.

#### [MODIFY] [hybrid_html5_engine.js](file:///c:/Users/jeff/StudioProjects/gdar/apps/gdar_web/web/hybrid_html5_engine.js)
- **Gap Reporting**: Ensure `_lastGapMs` is strictly numeric before returning it in `getState`.

---

### Core Data & Diagnostics (Dart)

#### [MODIFY] [audio_provider_diagnostics.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart)
- **LG Visibility**: Update the chip display logic to show `LG` even if the value is `0.0`, provided it is non-null.

## Open Questions
- Do we want to display `LG: 0.0ms` as a green success chip, or keep it as a standard white chip? (Currently proposing standard visibility).

## Verification Plan

### Automated Tests
- No new automated tests planned for this JS-to-Dart bridge fix, as it involves browser-specific timing.

### Manual Verification
1. **Handoff Check**: Play a track in `hybrid` mode with `hf buf`. Wait for boundary. Verify the tech label flips from `(H5B)` to `(WA)` instantly.
2. **LG Chip Check**: Verify `LG: XX.Xms` appears in the HUD after every track transition.
3. **Pause/Resume Check**: Pause during the first 10 seconds of a track. Verify `LG` report persists on resume.
