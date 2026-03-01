# [FIX] WebAudio [object Object] Error & Lifecycle Robustness
**Date**: 2026-02-27
**Time**: 13:30

Fix the opaque `[object Object]` error reporting in the web engine and improve `AudioContext` lifecycle management to prevent "playing" errors when the app is backgrounded or throttled.

## User Review Required

> [!IMPORTANT]
> This change modifies base JavaScript audio engine logic used by all web users. While it increases robustness, it should be verified across different browsers (Chrome, Safari).

## Proposed Changes

### Web Audio Engine (JS)

#### [MODIFY] [gapless_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/gapless_audio_engine.js)
- Update `_emitError` to check if the error is an object and extract `.message` and `.name`.
- Add defensive `.catch()` to all `_ctx.resume()` and `_ctx.suspend()` calls to prevent unhandled promise rejections.
- Enhance `_ensureContext` to detect if the context is `closed` and recreate it if necessary.
- Add additional checks in `play()` to ensure the context is `running` before starting source nodes.

#### [MODIFY] [hybrid_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/hybrid_audio_engine.js)
- Add logging for foreground/background handoffs to make transition failures easier to debug in the console.

---

### Dart Web Adapter (Interop)

#### [MODIFY] [gapless_player_web.dart](file:///home/jam/StudioProjects/gdar/lib/services/gapless_player/gapless_player_web.dart)
- Update `onError` signature to accept `JSAny` instead of `JSString`.
- Implement logic to check if the received error is a `JSObject` and extract the `message` property using `getProperty`.
- Ensure the error prefix "WebAudio: " is followed by a human-readable string.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure JS interop types are valid.
- Run `flutter test test/services/web_gapless_adapter_test.dart` to ensure no regressions in the provider-adapter contract.

### Manual Verification
1. **Error Reporting**:
   - Open the app in a browser.
   - Using DevTools console, manually trigger an error: `window._gdarAudio.onError({ message: "Simulated Error" })`.
   - Verify that the red error banner in the app shows `Playback Error: Exception: WebAudio: Simulated Error` (not `[object Object]`).
2. **Lifecycle Check**:
   - Start playback in Hybrid mode.
   - Switch tabs/background the app for ~30 seconds.
   - Return to the app and ensure playback resumes or transitions correctly without throwing a WebAudio exception.
3. **Console Audit**:
   - Inspect console logs for `[hybrid engine] Executing restore` and `[hybrid engine] Executing boundary handoff` to confirm the handoff logic is firing without errors.
