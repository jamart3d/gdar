# Hybrid Audio Engine — Deep Audit Report

**Date:** 2026-02-27 08:40 PST  
**Scope:** All Web JS engines, Dart JS-interop wrappers, `AudioProvider`, and `index.html`.  
**Status:** ✅ All 15 issues addressed.

---

## Architecture Overview

```
index.html load order
  1. html5_audio_engine.js   → window._html5Audio    (dual <audio>, near-gapless)
  2. gapless_audio_engine.js → window._gdarAudio     (Web Audio API, 0ms gapless)
  3. passive_audio_engine.js → window._passiveAudio   (single <audio>, background)
  4. hybrid_audio_engine.js  → window._hybridAudio    (orchestrates fg/bg handoff)
  5. hybrid_init.js          → Assigns window._gdarAudio based on strategy/override

Dart side
  ├─ gapless_player_web.dart  (primary bridge, talks to window._gdarAudio)
  ├─ hybrid_audio_engine.dart (dedicated bridge → window._hybridAudio)
  ├─ passive_audio_engine.dart(dedicated bridge → window._passiveAudio)
  └─ audio_provider.dart      (ChangeNotifier, owns GaplessPlayer)
```

---

## Issue Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Callback overwrite risk | 🔴 Critical | ✅ By-design (documented) |
| 2 | Foreground restore silent failure | 🔴 Critical | ✅ Fixed — falls back to passive |
| 3 | No OOM guard on decode | 🔴 Critical | ✅ Fixed — 100MB gate |
| 4 | Leaked StreamControllers | 🔴 Critical | ✅ Fixed |
| 5 | Both engines loaded simultaneously | 🟡 Moderate | ✅ Fixed — lazy loading |
| 6 | html5 getState missing field | 🟡 Moderate | ✅ Fixed |
| 7 | Passive null reference | 🟡 Moderate | ✅ Fixed |
| 8 | Pause evicts decoded buffer | 🟡 Moderate | ✅ Fixed — keeps compressed |
| 9 | iPadOS UA detection | 🟡 Moderate | ✅ Fixed — maxTouchPoints fallback |
| 10 | Missing viewport meta + typo | 🟡 Moderate | ✅ Fixed |
| 11 | Duplicate _JsTrack types | 🔵 Minor | ✅ Accepted — private per-file |
| 12 | Crossfade stubs | 🔵 Minor | ✅ Fixed — warns "not implemented" |
| 13 | MediaSession re-registration | 🔵 Minor | ✅ Fixed — register once in init |
| 14 | Watchdog 500ms overhead | 🔵 Minor | ✅ Fixed — 1000ms |
| 15 | Hardcoded manifest version | 🔵 Minor | ✅ Fixed — removed |

---

## Detailed Findings & Resolutions

### 🔴 Critical Issues

#### 1. Callback Overwrite — By Design ✅

The hybrid engine registers forwarding callbacks on both sub-engines, overwriting any previous Dart-side callbacks. This is intentional: only one Dart wrapper is active at a time, and the hybrid engine owns both sub-engines exclusively.

#### 2. Foreground Restore Fallback ✅ FIXED

If the Web Audio context fails to resume after a long background session, the engine now falls back to the passive engine and continues playback instead of entering a dead state with a frozen progress bar.

#### 3. OOM Guard on `decodeAudioData` ✅ FIXED

Added a 100MB compressed file size gate in `_decode()`. Tracks exceeding this threshold are rejected with a descriptive warning log, preventing the simultaneous ~250MB allocation (50MB copy + ~200MB decoded PCM) that could crash mobile browser tabs.

#### 4. Leaked StreamControllers ✅ FIXED

`_nextTrackBufferedController` and `_nextTrackTotalController` are now properly closed in `dispose()` in both `hybrid_audio_engine.dart` and `passive_audio_engine.dart`.

---

### 🟡 Moderate Issues

#### 5. Lazy Engine Loading ✅ FIXED

`hybrid_audio_engine.js` `setPlaylist()` and `appendTracks()` now only load the active engine. The inactive engine receives its full playlist lazily on first handoff, avoiding a wasted AudioContext creation and `<audio>` element allocation.

#### 6. html5 `getState()` Missing `currentTrackBuffered` ✅ FIXED

`getState()` now computes `currentTrackBuffered` from `audio.buffered.end()`, matching the logic already present in `_emitState()`.

#### 7. Passive Engine `_disposeAudio` ✅ FIXED

`_audio = null;` added after clearing listeners and src, preventing code paths from operating on a stale, dead HTMLAudioElement.

#### 8. Pause: Keep Compressed Cache ✅ FIXED

On pause, only the decoded PCM AudioBuffer (~100MB) is evicted for the next track. The compressed cache (~7MB) is retained, avoiding a re-fetch on resume.

#### 9. iPadOS Detection ✅ FIXED

Added `isIPadOS` detection via `navigator.maxTouchPoints > 4 && /Mac/i.test(ua)`. This correctly identifies iPadOS Safari which sends a desktop-class UA string. Wired into the detection branch for accurate diagnostic logging.

#### 10. Viewport Meta + Typo ✅ FIXED

Added `<meta name="viewport" content="width=device-width, initial-scale=1">`. Fixed "garteful" → "grateful".

---

### 🔵 Minor Issues

#### 11. Duplicate `_JsTrack` Types ✅ ACCEPTED

Evaluated extracting to a shared file. Decision: Keep private per-file. The types are 6 lines each, private (`_`-prefixed), and making them public increases API surface unnecessarily. Each wrapper is intentionally self-contained with its own engine binding.

#### 12. Crossfade Stubs ✅ FIXED

`setTrackTransitionMode('crossfade')` now logs a clear `console.warn` that crossfade is not yet implemented and falls back to gapless behaviour. Removed the dead TODO comment.

#### 13. MediaSession Registration ✅ FIXED

All three engines (`gapless`, `html5`, `passive`) now register `setActionHandler` callbacks once in `init()` and only update `metadata` on track change. Reduces 4 redundant handler registrations per track transition.

#### 14. Watchdog Interval ✅ FIXED

Reduced from 500ms to 1000ms. The 0.25s tolerance means a 1s poll catches missed endings with under 1.25s latency.

#### 15. Manifest Version ✅ FIXED

Removed hardcoded `?v=1.1.18` cache-busting from `manifest.json` link. Flutter's service worker handles cache invalidation.

---

## HTML5 Default Transition ✅

As of 2026-02-27, the default web audio engine has been transitioned from `hybrid` to `html5`. 

**Rationale:**
- **PWA Background Longevity:** The HTML5 engine uses native `<audio>` elements which browsers treat with much higher priority for background playback longevity compared to Web Audio API (`AudioContext`).
- **RAM Efficiency:** HTML5 engine uses native HTTP streaming, avoiding large heap allocations for PCM decoding.
- **Improved Stability:** Mobile browsers are less likely to kill tabs using standard HTML5 audio during long background sessions.

The `hybrid` engine remains available as an optional mode for users who prefer the foreground/background handoff strategy.

---

## Files Modified

| File | Changes |
|------|---------|
| `web/gapless_audio_engine.js` | OOM guard (#3), compressed cache on pause (#8), media session once (#13), watchdog 1s (#14) |
| `web/hybrid_audio_engine.js` | Foreground restore fallback (#2), lazy loading (#5), crossfade warning (#12) |
| `web/html5_audio_engine.js` | `currentTrackBuffered` in getState (#6), media session once (#13) |
| `web/passive_audio_engine.js` | Null after dispose (#7), media session once (#13) |
| `web/hybrid_init.js` | iPadOS detection (#9), **Transition to HTML5 default** |
| `web/index.html` | Viewport meta (#10), typo fix, manifest version (#15) |
| `lib/audio/hybrid_audio_engine.dart` | Close leaked StreamControllers (#4) |
| `lib/audio/passive_audio_engine.dart` | Close leaked StreamControllers (#4) |
| `lib/config/default_settings.dart` | **Set `audioEngineMode` to `html5`** |

---
*Audit completed 2026-02-27. All 15 issues addressed across 9 files.*
