# Wasm Stability Breakthrough Report

**Date:** March 10, 2026  
**Status:** Stability Verified (Puppeteer Stress Script Pass)

## Executive Summary
After rigorous investigation of the "Wasm UI Freeze" issue, we have successfully stabilized the build. The application now survives 120+ seconds of continuous playback, rapid tab switching ("Fruit Stress"), and visibility interruptions (backgrounding). 

The root cause was a combination of **NaN/Infinity unboxing crashes** in the Dart-Wasm layer and **asynchronous race conditions** in the JS-Interop bridge when the UI thread was under high load.

## Key Fixes Implemented

### 1. JavaScript Engine Hardening
*   **Finiteness Guards:** Re-introduced `isFinite()` checks in both `gapless_audio_engine.js` and `html5_audio_engine.js`. This prevents `NaN` or `Infinity` values (common in audio processing) from reaching the Dart `round()` or `int.parse` functions, which crash Wasm builds.
*   **Disconnect Safety:** Wrapped `AudioNode.disconnect()` in `try-catch` blocks. Prevents `InvalidAccessError` (thrown when a node is already disconnected or not yet connected) from bubbling up and hanging the JS-Interop bridge.

### 2. Dart JS-Interop Bridge Refinement
*   **Defensive Type Casting:** Replaced direct `as _GdarState` or `as _JsTrackChangeEvent` casts with safe `raw != null && raw.isA<JSObject>()` checks. Wasm's more rigid type system was failing on minified class names during rapid event emissions.
*   **Nullable Native Events:** Updated JS callbacks to accept `JSAny?` and handle nulls gracefully. This ensures that a late or malformed event from the JS engine does not crash the Dart runtime.

### 3. UI & Provider Null Safety
*   **Eliminated non-null Assertions:** Removed all `!` operators from `GaplessPlayer` and `utils.dart` (Fruit Overlay logic). These were identified as prime targets for the "Null check operator used on null value" crashes, especially when switching between tabs while the engine was still initializing.
*   **Stream Throttling:** Verified that the JS engine's state emissions are throttled to 250ms (4Hz). This reduces the pressure on the Flutter build engine during the critical first 60 seconds of playback.

## Verification Results
Using the `hybrid_stress.js` Puppeteer script, the build achieved the following:

| Phase | Cycles | Result |
| :--- | :---: | :--- |
| **Visibility Stress** | 20 | **PASS** (survived hidden/visible toggles) |
| **Fruit Tab Stress** | 15 | **PASS** (rapid switching between navigation bars) |
| **Track Transitions** | 10 | **PASS** (zero gap between multiple tracks) |
| **Persistence Monitor** | 120s+ | **PASS** (no UI stalls or heartbeat failures) |

## Remaining Considerations
*   **Performance Mode:** While stable, "Liquid Glass" effects still incur a CPU cost on low-end hardware. **Performance Mode (Simple Theme)** remains the recommended path for battery life on Web/Fruit.

> [!TIP]
> This stable Wasm baseline is now recommended for the production release pipeline.
