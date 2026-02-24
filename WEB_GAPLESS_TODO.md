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
- [ ] `run_tests` — all existing tests pass (native wrapper = no-op)
- [ ] Manual: `flutter run -d chrome` → play segue show → 0ms transitions
- [ ] Manual: Chrome DevTools `window._gdarAudio.getState()`
- [ ] Manual: Toggle Gapless Engine OFF → verify fallback
- [ ] Manual: Background tab 10 min → no stall
- [x] Investigate: Web UI playback does not play next track when screen is off
  - **Fixed in `gapless_audio_engine.js`**: `visibilitychange` → `ctx.resume()` on screen restore; eager `_fetchCompressed()` bypasses frozen `setTimeout`; 500ms watchdog catches missed `onended` callbacks.
