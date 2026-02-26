# Web Buffering & Prefetch Analysis Plan

**Date:** 2026-02-25
**Time:** 18:59

## Proposed Changes

### [Component] Audio Engine (Web)

#### [MODIFY] [gapless_player_web.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/services/gapless_player/gapless_player_web.dart)
- Created a dedicated `_bufferedPositionController` to track the actual buffered state from the engine.
- Fixed the `bufferedPositionStream` getter to use the new controller instead of the `positionStream`.

## Pre-fetch Intensity Analysis

### Memory Pressure (RAM)
The Custom Web Audio engine (Desktop) decodes tracks into raw PCM `AudioBuffer` objects.
- **Factor**: PCM data is uncompressed (~10MB/minute).
- **Intensity**: Increasing prefetch from 30s to 120s means the system holds the uncompressed next track in RAM for an extra 90 seconds.
- **Risk**: Higher risk of tab crashes on memory-constrained devices (Mobile Safari/Chrome) due to prolonged peak memory usage.

### CPU & Decoding
- **Intensity**: No extra work is done; the decoding happens once regardless of timing. However, triggering it earlier provides more "safety" against network stutters.

### Recommendations
1. **Desktop**: High values (60s+) are safe and recommended for reliability.
2. **Mobile**: Values should be kept moderate (15s-30s) to avoid excessive memory duration.

## Verification Plan

### Automated Tests
- Run `flutter analyze` via Dart MCP to ensure no regressions.
