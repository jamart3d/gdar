# Screensaver Technical Specification

### 1. Motion Decoupling (v1.1.60+)
The screensaver utilizes a decoupled motion system to ensure visual stability:

* **Independent Translation:** The track info (text rings/flat banner) must translate its base position based on the `targetPos` and `speed` uniforms, independent of the `energy` or `beatPulse` values.
* **Reactivity Scaling:** Audio reactivity (`pulseIntensity`) should only affect the *scale* or *glow intensity* of the elements, never their $x/y$ coordinates.
* **Sub-pixel Snapping:** When `oilBannerPixelSnap` is enabled, the calculated coordinates must be rounded to the nearest integer pixel *after* all interpolation to eliminate "crawling" letters during slow translation.

### 2. Graph Rendering Modes
The Audio Graph (`StealGraph`) supports adaptive performance buckets:

* **High Performance:** Full Gaussian glow, 8-band gradients, and peak-hold capsules.
* **Balanced:** Solid color gradients, reduced blur radius, 4-band simplified visualization.
* **Fast (Low Power):** No blurs, solid color bars, no peak-hold calculation.

### 3. Native Android Visualizer (VisualizerPlugin.kt)
The native bridge provides a 4-band energy map:
* **Bass (20-150Hz):** Drives `beatPulse` and `uBass`.
* **Mid (150-2000Hz):** Drives `uMid`.
* **Treble (2000+Hz):** Drives `uTreble`.
* **Overall:** Drives `uOverall` for global luminosity.
