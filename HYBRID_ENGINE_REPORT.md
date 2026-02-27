# Hybrid Audio Engine Behavior Report

This report documents the behavior of the GDAR Hybrid Audio Engine (Web) regarding error reporting, snackbars, and background playback handling.

## 1. Snackbar Trigger Mechanisms

In the GDAR Web UI, snackbars are triggered via the `playbackErrorStream` in `AudioProvider.dart`. For the Hybrid Engine, these messages typically originate from:

### Fatal Playback Failures
If the underlying JavaScript engines (`_gdarAudio` for foreground or `_passiveAudio` for background) encounter a fatal error, they bubble a `'hybrid engine error'` event to Dart. 
- **Causes**: 404 Not Found, CORS blocks, or network timeouts.
- **Result**: `Playback Error: hybrid engine error` snackbar.

### Playlist Load Failures
If the initial source loading via `setAudioSources` fails:
- **Causes**: Invalid track URLs or browser auto-play policy rejections.
- **Result**: `Error playing source: [error details]` snackbar.

---

## 2. Background Visibility & Handoff

The Hybrid Engine manages transitions between the high-performance Web Audio API (Foreground) and the stable HTML5 Audio element (Background) based on tab visibility.

### Boundary Handoff Strategy
When the tab is hidden (`document.visibilityState === 'hidden'`), the engine **does not** stop immediately.
- It sets a `_pendingHandoff` flag.
- The switch to the background engine occurs **only at the track boundary**. This ensures gapless playback is maintained without an audible glitch mid-track.

### Issue Handling in Background
- **Error Propagation**: If a track fails to load while the app is in the background, the error is still forwarded to Dart. However, since the browser throttles UI updates for hidden tabs, the snackbar may not appear until the user returns to the app.
- **Suppressed Restoration Errors**: When the user returns to the tab (`visibilitychange` -> visible), the engine attempts a "Foreground Restore" (re-syncing the Web Audio graph to the HTML5 position). 
  - **Crucially**: If this restoration fails, the Hybrid Engine **suppresses the error** (it logs to console but does not forward to Dart).
  - **Reasoning**: To prevent "transient" error snackbars caused by browser throttling or context loss during tab switching, ensuring a smoother user experience upon return.

---
*Generated on 2026-02-27*
