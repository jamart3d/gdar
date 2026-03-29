---
trigger: audio, playback, engine, web, native, canvas, render
policy_domain: Audio Engine
---
# Audio Engine & Technical Calibration

This document consolidates the architectural and operational rules for the GDAR playback engines (Native and Web) and low-level rendering calibration.

## 1. Cross-Platform Strategy
- **Native (Phone/TV)**: Use `just_audio` with `just_audio_background`. Use **Hive** for metadata caching.
- **Web / PWA**: Use the custom **Gapless Web Audio Engine** stack (`apps/gdar_web/web/`).
- **Engine Logic Isolation**: Never mix UI rendering with core playback state. Use `currentIndexStream` or `MediaItem` tag streams as the authoritative sync source.

## 2. Web Engine Architecture
- **Load Order**: `audio_utils.js` → `audio_scheduler.js` (Worker) → Engine files → `hybrid_init.js`.
- **High-Precision Timing**: All transitions (handoffs, crossfades, look-ahead) MUST use the `gapless_audio_engine.js` scheduler, not Dart `Timer`.
- **Throttling Awareness**: Assume 6x CPU slowdown. Schedule events **look-ahead** on `AudioContext.currentTime` timeline, never "just-in-time".

## 3. Web Audio Prefetch Integrity
- **Protection Window**: During `_cancelPrefetch`, the current track and the immediate next track MUST be protected.
- **Abortion Collision Prevention**: Prevent manual track selection from killing its own fetch request by injecting the target index into the cancellation whitelist.

## 4. Mode Resolution (Resolved vs. Stored)
- `sp.audioEngineMode` may be `auto`. Always gate UI on the **resolved** mode:
  ```dart
  audioProvider.audioPlayer.activeMode
  ```
- This applies to Hybrid Handoff selectors, Background Survival strategies, and engine-specific HUD chips.

## 5. Canvas Rendering Jitter Calibration
When implementing slow-moving animations or precise text rendering using `Canvas.translate()` or `Canvas.drawImage()`, always prevent sub-pixel artifacting (often referred to as "crawling" or "jitter").
- **Integer Coordinates**: When translating coordinates that may evaluate to fractional pixels during an `update(dt)` loop, explicitly round the values using `.roundToDouble()` or `.round()` on the X and Y coordinates before applying the translation. Sub-pixel rendering on hardware displays often attempts to anti-alias across grid boundaries, causing independent letters or pixels to jump inconsistency.
- **Settings Toggles**: If sub-pixel movement might be desired at higher speeds, wrap the rounding logic in a configuration boolean parameter (e.g., `pixelSnap`) to allow users to toggle the sub-pixel lock logic over their own device's refresh rate capabilities.
