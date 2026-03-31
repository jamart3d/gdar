# Issue Report: Hybrid Audio Engine Handoff & LG Chip Failure

**Date:** 2026-03-31
**System:** Web UI (Hybrid Audio Orchestrator)
**Severity:** High (Metric Loss & Sync Inefficiency)

## 1. Overview
The hybrid audio engine fails to reliably hand off from `H5B` (HTML5 Buffer) to `WA` (Web Audio) at track boundaries under specific conditions (`hf buf`, `bg off`, `stb max`). Additionally, the `LG` (Last Gap) chip report is missing from the HUD, preventing performance verification.

## 2. Root Cause Analysis

### A. Handoff Stickiness (H5B -> WA)
- **State Pinned to H5B:** In `hybrid_audio_engine.js`, `_handoffInProgress` is used to "pin" the tech label to `(H5B)` during transitions to prevent flickering. 
- **The Race:** In `_executeForegroundRestore`, `_handoffInProgress` is set to `false` **after** the completion broadcast (`_onTrackChange`). If the Dart HUD polls `getState()` at the moment of transition, it sees `_handoffInProgress = true` and `_activeEngine = _fgEngine`, which triggers the forced `(H5B)` label in `getState` (lines 1086-1088).
- **Concurrency Guard:** The `_handoffRunId` is incremented on every track change, correctly killing stale restore loops, but if the WA sub-engine takes >5s to reach `ready` state, the restore aborts and stays on H5.

### B. Missing LG Chip Report
- **Orchestrator Level:** `_lastGapMs` in the hybrid orchestrator is cleared during `pause()`, `seek()`, and `stop()`. If a user interacts during a transition, the gap measurement is lost.
- **Sub-Engine Silence:** In `hybrid_html5_engine.js`, `_lastGapMs` is computed at the boundary. However, if the hybrid orchestrator "Stays in HTML5" (due to `hf buf` optimization for short tracks), it relies on the sub-engine's `lastGapMs`. 
- **Transmission Gap:** The `_forwardState` logic in the orchestrator does not always persist the sub-engine's gap if it arrives during an active handoff window, as it prefers its own `_lastGapMs` which might be null.

## 3. Findings from Instrumentation Trace
- **`stb max` (Max Gapless):** This preset sets `handoffMode = buffered`. For many tracks, the HTML5 buffer is sufficient, causing the orchestrator to stay on H5. The "restore" to WA ONLY happens at the next boundary.
- **`isReady` Condition:** `fgState.playing && fgState.processingState === 'ready'`. If the Web Audio engine remains in `buffering` or `loading` for >5s after the H5 engine has finished the transition, the handoff fails.

## 4. Proposed Fixes

### 1. Fix Handoff Completion (JS)
Move `_handoffInProgress = false` **before** the completion broadcast in `_executeForegroundRestore` to ensure the tech label flips to `(WA)` immediately upon success.

### 2. LG Gap Persistence (JS)
Ensure `_lastGapMs` is correctly captured from the active sub-engine even when the orchestrator is not performing a cross-engine restore.

### 3. HUD Visibility (Dart)
Ensure `AudioProviderDiagnostics` does not filter out `0.0ms` values if they represent a successfully measured (perfect) gap, as "missing" implies failure.

## 5. Next Steps
1. Apply `hybrid_audio_engine.js` patch to move `_handoffInProgress` reset.
2. Add instrumentation to `_executeForegroundRestore` to log `isReady` components.
3. Verify `LG` visibility in `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`.
