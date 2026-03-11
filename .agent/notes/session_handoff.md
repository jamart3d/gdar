# Session Handoff — Wasm Initialization & Playback Hang Fixes
**Date:** 2026-03-10  
**Status:** Both fixes implemented, awaiting final local verification before live deploy.

---

## 1. Playback Hang (Fixed ✅)
**Problem:** The UI locked up completely when playback started on web.
**Root Cause:** If the browser blocked autoplay (no user gesture), `AudioContext.resume()` completed successfully, but the state remained `suspended`. The JavaScript gapless audio engine (`web/gapless_audio_engine.js`) incorrectly retried `api.play()` in an infinite async microtask loop because the state was check was flawed.
**Fix:** Updated `gapless_audio_engine.js` line 665 to strictly verify `_ctx.state === 'running'` before recursion. If blocked, playback aborts gracefully and warns without locking the main thread.

## 2. Initialization Crash / "Failed to load shows" (Fixed ✅)
**Problem:** The live PWA crashed purely from `dart:io` symbols being included in the Wasm compilation boundary.
**Root Causes & Fixes:**
- **`audio_cache_service.dart`**: Fixed conditional export target (`html` → `js_interop`).
- **`show_list_provider.dart`**: Removed direct `dart:io` import, handled exception generically.
- **`catalog_service.dart`**: Bypassed Hive completely on web paths because `hive` v2 uses `dart:io` under the hood. To satisfy the UI widgets needing a `Box<T>`, a minimal in-memory `_WebBox<T>` stub class now implements the interface no-ops gracefully.
- **Blocking JSON Parse:** Wrapped `parseShows` in `Future.microtask` to prevent the heavy JSON decode from freezing the UI on load in Wasm.

---

## Current State
- `flutter build web --wasm` compiled cleanly without IO errors.
- New Wasm build is actively being served on `http://localhost:8080`.

## Next Steps
1. **Refresh `http://localhost:8080`** (Hard Refresh to clear browser cache).
2. Validate that the shows list loads instantly and doesn't hang.
3. Validate that playback starts correctly (ensure you click on the page to grant AudioContext permission).
4. If everything looks good, call `/save` to commit.
5. Deploy to prod using `firebase deploy --only hosting:shakedown-pwa`.
6. Run `/session_debrief` to log the Wasm architecture learnings.
