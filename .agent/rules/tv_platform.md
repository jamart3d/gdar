---
trigger: tv, screensaver, focus, flow, navigation, "android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt"
policy_domain: TV Platform
---
# Google TV Platform & UI Flow Directives

### 1. Focus & Navigation
* **Action:** Wrap every interactive TV element in `TvFocusWrapper` (1.05x scale + glow border).
* **Action:** Dim inactive panes or background elements to 0.2 opacity when focus is elsewhere.
* **Action:** Use a standardized duration for transitions (prefer `<100ms` for premium feel over `0ms` instant) to ensure focus clarity.
* **Constraint:** Never use tactile/haptic feedback on TV builds. Focus is purely visual. This constraint applies to the entire app and the screensaver flow.
* **Constraint:** Never use organic ripples or spring animations on TV; stick to direct linear or fast-out/slow-in transforms.

### 2. Surgical Stabilization
When creating focusable elements for TV (e.g., list items, buttons):
- **Constraint:** The widget tree structure MUST remain identical whether the item is focused or unfocused.
- **Action:** Do not conditionally mount/unmount padding, borders, or wrappers based on focus state. Instead, toggle the *properties* of those widgets (e.g., set border width to 0 or color to transparent when unfocused).
- **Reason:** Mounting/unmounting widgets during fast D-pad navigation causes layout shifts ("bounce scroll"), breaks internal focus tracking, and leads to infinite focus loops.

### 3. ValueKey Synchronization
When rendering dynamic lists (e.g., Show Lists, Track Lists):
- **Constraint:** Every item in a scrollable list MUST have a unique, stable `ValueKey`.
- **Action:** Use domain-specific IDs (e.g., `ValueKey(show.identifier)` or `ValueKey(track.id)`). Do not use index-based keys.
- **Reason:** Stable keys ensure Flutter's element tree correctly matches state to list items during rapid scrolling and dataset updates, preventing focus from becoming detached or jumping to the wrong item.

### 4. Optimization [CRITICAL]
* **Action:** Use a **Rasterized Glyph Cache** (`Map<String, ui.Image>`) for `StealBanner` neon glow effects. Rasterize glyph blurs to off-screen surfaces once to prevent GPU thrashing.

### 5. Screensaver
* **Action:** Always consult `.agent/specs/tv_screensaver_spec.md` before modifying screensaver logic.
* **Constraint:** TV exclusivity is absolute. Never implement screensaver triggers on mobile or web.

### 6. Android Visualizer Calibration (TV Beat Detection)
To prevent audio reactivity controls from causing unintended frequency-based trigger side effects:
* **Pre-Boost Beat Detection:** Always use the raw bass energy (`beatBass`) for beat detection thresholds, *before* applying the user's `bassBoost` or `overallStrength` multipliers. This ensures that increasing "Bass Boost" in settings only affects the *visual magnitude* of the pulse, not the *frequency* of the pulse triggers.
* **Historical Thresholding:** When updating the beat detection logic in `VisualizerPlugin.kt`, ensure the current frame's energy is compared against the *previous* threshold value before being added to the history buffer. This maintains detection sensitivity regardless of volume or boost levels.
* **Native-to-Dart Sync:** Ensure any changes to `oilAudioPeakDecay` in `default_settings.dart` are clamped to values the native `VisualizerPlugin.kt` can handle without floating point overflows (typically `0.99x` range).
