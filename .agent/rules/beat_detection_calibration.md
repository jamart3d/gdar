---
trigger: "android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt"
---
# Android Visualizer Calibration Rule

To prevent audio reactivity controls from causing unintended frequency-based trigger side effects:

### 1. Pre-Boost Beat Detection
* **Action:** Always use the raw bass energy (`beatBass`) for beat detection thresholds, *before* applying the user's `bassBoost` or `overallStrength` multipliers.
* **Reason:** This ensures that increasing "Bass Boost" in settings only affects the *visual magnitude* of the pulse, not the *frequency* of the pulse triggers.

### 2. Historical Thresholding
* **Action:** When updating the beat detection logic in `VisualizerPlugin.kt`, ensure the current frame's energy is compared against the *previous* threshold value before being added to the history buffer.
* **Reason:** This maintains detection sensitivity regardless of volume or boost levels.

### 3. Native-to-Dart Sync
* **Action:** Ensure any changes to `oilAudioPeakDecay` in `default_settings.dart` are clamped to values the native `VisualizerPlugin.kt` can handle without floating point overflows (typically `0.99x` range).
