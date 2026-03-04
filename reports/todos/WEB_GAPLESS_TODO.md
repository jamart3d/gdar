# True Gapless Web Playback — TODO

**Date:** 2026-02-23T19:04 PST

0ms gapless via `AudioBufferSourceNode.start(exactEndTime)` — audio thread stitches tracks at the sample boundary.

---

## JS Audio Engine
- [x] Create `web/gapless_audio_engine.js`
  - [x] AudioContext + GainNode lifecycle
  - [x] Safari user gesture handler (`AudioContext.resume()`)
  - [x] Playlist management (`setPlaylist`, `appendTracks`)
  - [x] Fetch + decode pipeline (`fetch()` → `decodeAudioData()`)
  - [x] AudioBufferSourceNode scheduling (0ms transitions)
  - [x] Position/duration tracking via `AudioContext.currentTime`
  - [x] Play/pause (`suspend/resume`), stop, seek, seekToIndex
  - [x] Configurable prefetch timing
  - [x] Media Session API (browser media controls)
  - [x] Callbacks to Dart (`onStateChange`, `onTrackChange`, `onError`)

## GaplessPlayer Abstraction
- [x] Create `lib/services/gapless_player/gapless_player.dart` (conditional export)
- [x] Create `lib/services/gapless_player/gapless_player_native.dart` (just_audio wrapper)
- [x] Create `lib/services/gapless_player/gapless_player_web.dart` (JS interop adapter)

## Integration
- [x] `audio_provider.dart` — `AudioPlayer` → `GaplessPlayer`
- [x] `buffer_agent.dart` — `AudioPlayer` → `GaplessPlayer`
- [x] `web/index.html` — add `<script src="gapless_audio_engine.js">`
- [x] `pubspec.yaml` — add `web: ^1.1.1`

## Settings (Playback Section, web-only)
- [x] `default_settings.dart` — add `webGaplessEngine` (bool, true), `webPrefetchSeconds` (int, 30)
- [x] `settings_provider.dart` — add keys, fields, getters, setters
- [x] `playback_section.dart` — add `if (kIsWeb)` block:
  - [x] Gapless Engine toggle (on/off)
  - [x] Prefetch Ahead slider (5–60s, visible when engine ON)

## Verification (Dart MCP)
- [x] `analyze_files` — zero errors on new and modified files
- [x] `run_tests` — all existing tests pass (native wrapper = no-op)
- [x] Manual: `flutter run -d chrome` → play segue show → 0ms transitions
- [x] Manual: Chrome DevTools `window._gdarAudio.getState()`
- [x] Bug: Track overlapping occasionally on background tab transitions
- [x] Bug: Mini player track title not updating on track change (web only)
- [x] Bug: Mini player play/pause button state not syncing with actual playback state (web only)
- [x] Bug: Random playback on new playlist failing to unpause
- [x] Feature: Show loading spinner in mini player while track is buffering/decoding (web only)

## JS Audio Engine Optimization (Option 3)
- [x] Implement `AbortController` in `_fetchCompressed` to cancel pending downloads
- [x] Add `_cancelFetch(index)` method to abort pending fetch requests (handled via direct `_abortControllers` logic)
- [x] Update `_evictOldBuffers` to delete `_compressed[index]` as well as `_decoded`
- [x] Call `_cancelFetch` in `stop()`, `seekToIndex()`, and `setPlaylist()`

## Post-Release Refinements
- [x] **Regression Testing**: Implement automated regression tests for the JS Gapless Audio Engine adapter (`web_gapless_adapter_test.dart`).
- [x] **UI Sync**: Fix issue where Web UI does not update properly (stale track/state info). Implemented synthetic `PlaybackEvent` emission.
- [x] **Wakelock**: Investigate "Keep Screen On" behavior for mobile web. Confirmed `wakelock_plus` support via Wake Lock API.
- [ ] **Background Longevity**: Investigate ways to extend playback duration when the tab is backgrounded/tab-throttled.
    - [ ] Explore `Silent Video` looping or `Web Workers` for timer consistency.
    - [ ] Audit `gapless_audio_engine.js` for potential timer drift during high CPU throttling.

- [ ] **Bug: Track Skip on Buffer**: Investigate issue where the engine skips the next track if it isn't fully ready/buffered when the current track ends.

## Hybrid Audio Architecture (Relisten + GDAR Engine) ✅
- [Reference: Relisten's `gapless.cjs`](https://github.com/RelistenNet/relisten-web/blob/master/public/gapless.cjs)
- [x] Refactor audio architecture to a Hybrid Strategy unifying HTML5 `<audio>` and Web Audio API (`AudioBufferSourceNode`).
- [x] Implement `DeviceDetector` utility to check `navigator.userAgent` and touch capabilities — done in `hybrid_init.js`.
- [x] Mobile Strategy (Relisten style): `web/relisten_audio_engine.js` — dual-HTML5-Audio-element approach on mobile devices. Supports streaming, saves RAM/Data, prevents browser tab kills. Handles iOS Safari 'Audio Resume' (user gesture) via silent play/pause prime.
- [x] Desktop Strategy (GDAR Engine): Existing `web/gapless_audio_engine.js` — Web Audio API logic for 0ms gapless playback. Maintains Watchdog timer and MediaSession integration.
- [x] Unified API: Both strategies expose `play()`, `pause()`, `seek()`, `setPlaylist()`, `seekToIndex()`, `setPrefetchSeconds()`, `getState()`, `onStateChange`, `onTrackChange`, `onError`. `hybrid_init.js` assigns the correct strategy to `window._gdarAudio` — Dart interop requires zero changes.
- [x] Transition Logic: `hybrid_init.js` reads `userAgent` + `maxTouchPoints + innerWidth < 1024`; runs once at page load.
- [x] Validate and map Web Gapless settings (Prefetch threshold, Gapless Toggle) across the two strategies:
    - **GDAR Engine (Desktop)**: Continues to prefetch X seconds ahead (user-defined setting).
    - **Relisten Strategy (Mobile)**: `setPrefetchSeconds(s)` triggers `_nextAudio.load()` N seconds before track end.
    - **UI Settings**: `playback_section.dart` updated — shows context-aware labels ('HTML5 Audio Engine' on mobile, 'Gapless Engine' on desktop). Toggle now shows SnackBar requiring reload.
- [x] **PWA Strategy & Control**: Auto-detect + Off. `hybrid_init.js` detects mobile/desktop; toggle 'off' falls back to `just_audio` via existing `GaplessPlayer` fallback path.
    - *Media Session*: Both engines integrate Media Session API for lock-screen controls.
    - *Error Fallback*: If the toggle is off, `GaplessPlayer` uses `just_audio` (existing behavior).
- [ ] **Future Enhancement**: Add a user setting to allow choosing how many tracks to buffer/preload ahead of time on mobile (the system currently defaults to 1).
