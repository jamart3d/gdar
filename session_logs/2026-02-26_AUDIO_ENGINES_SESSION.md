# 2026-02-26_AUDIO_ENGINES_SESSION: Audio Engines (Passive & Hybrid)

## Hypotheses
*   We need to implement a Passive Web Engine and a Hybrid Web Engine to replace the reliance on background audio hacks (silent video / worker heartbeat).
*   The Passive engine uses a simple HTML5 `<audio>` tag and MediaSession API without Web Audio API or workers. Background playback is natively handled by the browser.
*   The Hybrid engine uses Web Audio API for gapless/crossfade in the foreground and hands off to the Passive engine when backgrounded.
*   We also need to introduce a Track Transition mode (gap/gapless/crossfade) and crossfade duration settings.

## Running Summary
*   Investigated project structure; web gapless engines bind to `window._gdarAudio`.
*   Creating implementation plan.

## Bug Tracker
*   None yet.

## Handoff
*   Current System State: Creating implementation plan for user review.
