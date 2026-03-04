# Implementation Plan: Web Audio Full Track Buffering (2026-02-27 16:35)

The user noticed that only "partial" buffering occurs in the Web Audio engine. This is due to:
1. **Instant Start**: The `HybridAudioEngine` uses HTML5 `<audio>` for immediate playback while the Web Audio graph (which needs the full file) prepares in the background. HTML5 buffers progressively.
2. **Next Track Prefetch Window**: Current logic waits until 30s before track end to fetch the next track.

## Proposed Changes

### [Component] Web Audio Engine (JS)

#### [MODIFY] [gapless_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/gapless_audio_engine.js)
- **Immediate Prefetch**: Update `_schedulePrefetch` to trigger `_fetchCompressed` for the next track as soon as the current track starts playback, rather than waiting for the prefetch window.
- **Full Buffer Reporting**: In `_emitState`, explicitly set `currentTrackBuffered` to the full `duration` if the track is fully decoded in an `AudioBuffer`.

### [Triple-Check & Gap Diagnostics]

#### [MODIFY] [hybrid_init.js](file:///home/jam/StudioProjects/gdar/web/hybrid_init.js)
- **STRICT ENFORCEMENT**: If `override === 'webAudio'`, the engine *must* be `window._gdarAudio`. If missing, the app will fail to load audio rather than falling back to a gap-prone engine.
- **Diagnostic Logging**: Added console logs to print exactly what was found in `localStorage` and the final engine assignment.

#### [MODIFY] [gapless_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/gapless_audio_engine.js)
- **Transition Heartbeat**: Added millisecond-accurate logs for `_startTrack` and `_onTrackEnded`.
- **Gap Detection**: Explicitly log a `WARN` if `_onTrackEnded` fires but no scheduled source exists.
- **Network Speed**: Note: No automatic fallback for network speed exists; a slow network will simply cause a gap *within* Web Audio while waiting for the next buffer.

#### [MODIFY] [gapless_player_web.dart](file:///home/jam/StudioProjects/gdar/lib/services/gapless_player/gapless_player_web.dart)
- **Console Proof**: Add `print()` statements that show the active engine strategy and reason during initialization.

#### [MODIFY] [hybrid_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/hybrid_audio_engine.js)
- **Swap Reporting**: Ensure that when the engine is in `foreground` mode (Web Audio), the state reported to Dart uses the `currentTrackBuffered` value from the Web Audio engine (which will be 100%).

### [Component] Audio Engine (Dart)

#### [MODIFY] [hybrid_audio_engine.dart](file:///home/jam/StudioProjects/gdar/lib/audio/hybrid_audio_engine.dart)
- **Eager Prefetch Config**: Update `setAudioSources` to pass a high prefetch value or ensure the JS engine defaults to eager prefetching when in "Web Audio" mode.

## Verification Plan

### Manual Verification
1. **Engine Selection**: Select 'Web Audio' in settings.
2. **Immediate Next-Track Fetch**: Start a track and open the browser's Network tab. The *next* track should start downloading immediately.
3. **Current Track 100% Buffer**: Observe the progress bar. After the initial "Instant Start" phase, once the swap to Web Audio occurs, the buffering bar for the current track should snap to 100% (full green/filled).
