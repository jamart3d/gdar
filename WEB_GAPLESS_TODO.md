# True Gapless Web Playback — TODO

**Date:** 2026-02-23T19:04 PST

0ms gapless via `AudioBufferSourceNode.start(exactEndTime)` — audio thread stitches tracks at the sample boundary.

---

## JS Audio Engine
- [ ] Create `web/gapless_audio_engine.js`
  - [ ] AudioContext + GainNode lifecycle
  - [ ] Safari user gesture handler (`AudioContext.resume()`)
  - [ ] Playlist management (`setPlaylist`, `appendTracks`)
  - [ ] Fetch + decode pipeline (`fetch()` → `decodeAudioData()`)
  - [ ] AudioBufferSourceNode scheduling (0ms transitions)
  - [ ] Position/duration tracking via `AudioContext.currentTime`
  - [ ] Play/pause (`suspend/resume`), stop, seek, seekToIndex
  - [ ] Configurable prefetch timing
  - [ ] Media Session API (browser media controls)
  - [ ] Callbacks to Dart (`onStateChange`, `onTrackChange`, `onError`)

## GaplessPlayer Abstraction
- [ ] Create `lib/services/gapless_player/gapless_player.dart` (conditional export)
- [ ] Create `lib/services/gapless_player/gapless_player_native.dart` (just_audio wrapper)
- [ ] Create `lib/services/gapless_player/gapless_player_web.dart` (JS interop adapter)

## Integration
- [ ] `audio_provider.dart` — `AudioPlayer` → `GaplessPlayer`
- [ ] `buffer_agent.dart` — `AudioPlayer` → `GaplessPlayer`
- [ ] `web/index.html` — add `<script src="gapless_audio_engine.js">`
- [ ] `pubspec.yaml` — add `web: ^1.1.1`

## Settings (Playback Section, web-only)
- [ ] `default_settings.dart` — add `webGaplessEngine` (bool, true), `webPrefetchSeconds` (int, 30)
- [ ] `settings_provider.dart` — add keys, fields, getters, setters
- [ ] `playback_section.dart` — add `if (kIsWeb)` block:
  - [ ] Gapless Engine toggle (on/off)
  - [ ] Prefetch Ahead slider (5–60s, visible when engine ON)

## Verification (Dart MCP)
- [ ] `analyze_files` — zero errors on new and modified files
- [ ] `run_tests` — all existing tests pass (native wrapper = no-op)
- [ ] Manual: `flutter run -d chrome` → play segue show → 0ms transitions
- [ ] Manual: Chrome DevTools `window._gdarAudio.getState()`
- [ ] Manual: Toggle Gapless Engine OFF → verify fallback
- [ ] Manual: Background tab 10 min → no stall
