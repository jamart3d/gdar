# Implementation Plan - Background Playback Longevity
Date: 2026-02-26 14:10

To improve background playback stability without keeping the physical screen on, we will implement a "Background Longevity" mode. This feature will be a **web-only setting**, **defaulting to off**.

## Proposed Changes

### Configuration & UI

#### [MODIFY] [default_settings.dart](file:///home/jam/StudioProjects/gdar/lib/config/default_settings.dart)
- Add `enableBackgroundLongevity = false`.

#### [MODIFY] [settings_provider.dart](file:///home/jam/StudioProjects/gdar/lib/providers/settings_provider.dart)
- Add preference key `enable_background_longevity`.
- Add getter/setter and initialization logic.

#### [MODIFY] [playback_section.dart](file:///home/jam/StudioProjects/gdar/lib/ui/widgets/settings/playback_section.dart)
- Add a new `TvSwitchListTile` for "Background Longevity" in the web-only section.
- Description: "Uses Web Workers and silent media to prevent background throttling (Battery intensive)."

### Web Audio Engine & Heartbeat

#### [NEW] [worker_timer.js](file:///home/jam/StudioProjects/gdar/web/worker_timer.js)
Create a dedicated Web Worker to act as a high-precision heartbeat.
- Implementation: A simple `setInterval` that posts a 'tick' message every 250ms.

#### [MODIFY] [gapless_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/gapless_audio_engine.js)
- **Worker Integration**: Replace `_positionTimer` and `_watchdogTimer` with listeners for the `worker_timer.js` heartbeat when longevity is enabled.
- **Silent Video Hack**: Implement `_startKeepAlive()` that plays a tiny base64-encoded silent video on a loop in a hidden `<video>` element if longevity is enabled.
- **Watchdog Improvement**: Use the worker heartbeat for watchdog checks.

#### [MODIFY] [html5_audio_engine.js](file:///home/jam/StudioProjects/gdar/web/html5_audio_engine.js)
- Integrate the worker heartbeat and silent video hack.

## Verification Plan

### Manual Verification
1. **Background Heartbeat Test**: Verify logs continue at ~4Hz when minimized with longevity ENABLED.
2. **Throttling Test**: Verify logs SLOW DOWN or STOP when minimized with longevity DISABLED (sanity check).
3. **Screen Off Test**: Confirm the physical screen STILL TURNS OFF normally (longevity should not keep it on).
