# TV Screensaver UI Specification (GDAR)

This document outlines the current state, architecture, specifications, and future development plans specifically for the **TV Screensaver** feature within GDAR's TV experience. The screensaver uses a fully custom generative visualizer ("Steal Your Face") to prevent screen burn-in while providing a highly aesthetic, audio-reactive experience tailored for Google TV and Android TV hardware.

**Monorepo scope:** Shared screensaver logic and widgets primarily live in `packages/shakedown_core`, while TV-specific routing and app behavior live in `apps/gdar_tv`.

**Shipping Android Host Note:** The TV screensaver remains a TV-only feature at the Dart/UI layer, but the Play-distributed Android App Bundle currently ships from `apps/gdar_mobile` under the shared package `com.jamart3d.shakedown`. Any native Android hardening for the TV screensaver audio path (for example `MainActivity.kt`, `VisualizerPlugin.kt`, `StereoCapture.kt`, MediaProjection/foreground-service wiring, or manifest permissions/services) must be mirrored in the shipping mobile host as well as `apps/gdar_tv` until the Android hosts are fully de-duplicated.

## 1. Current State & Architecture

### **Core Trigger Mechanism**
- **Service:** `InactivityService` monitors user interaction across the TV application.
- **Trigger:** Activates automatically after a default period (e.g., 5 minutes) of remote inactivity if the `useOilScreensaver` setting is enabled.
- **Guardrails:** When triggered, the screensaver (`ScreensaverScreen.show`) explicitly stops the `InactivityService` to prevent multiple hardware key events from stacking overlapping screensaver routes. Once the screensaver is dismissed, the service restarts.
- **Dismissal:** Any `KeyDownEvent` captured by a global `HardwareKeyboard` handler pops the screensaver route and returns the user to the underlying application state (e.g., dual-pane UI or Dive Mode).

### **Visuals & Audio Reactivity (`StealVisualizer`)**
- **Configuration:** Driven by `StealConfig`, which provides over 35 parameters controlling flow speed, palettes, film grain, translation smoothing, and audio beat sensitivity.
- **Audio Reactor:** Integrates smoothly via `AudioReactorFactory`. When audio reactivity is enabled (`oilEnableAudioReactivity`), it hooks into the native Android Audio Session ID.
    - **Source Agnostic:** Because it hooks into the hardware-level audio session, the visualizer will react to *any* audio being output by the application's `AudioProvider` (e.g., Archive.org streams, Phish.in, or local drive playback).
    - It maps decibel and frequency bands directly to the visualizer's pulse rate and heat drift variables.

### **Beat Detection & Audio Graph Visualization**
- **Graph Modes (`oilAudioGraphMode`)**: The visualizer features a dedicated 9-band EQ graph that visualizes the raw audio data driving the shaders. It operates in two modes:
    - **Corner Mode**: A traditional 8-band EQ anchored to the bottom-left of the screen. It features a distinct **9th bar specifically for Beat Detection** that violently spikes upon rhythmic onset. All 9 bars feature vertically rotated typography labels (e.g., SUB, BASS, LMID... BEAT) for precise debugging and aesthetic monitoring.
    - **Circular Mode**: An 8-band radial EQ that dynamically calculates its minimum radius and center point based on the active `game.smoothedLogoPos`. This allows the frequency bars to seamlessly "sprout" from underneath the transparent halo edge of the floating generative logo as it orbits the screen, creating a cohesive, unified visualizer without clipping.

### **Performance Tuning & Shader Scalability**
- **Performance Levels (`oilPerformanceLevel`):** The screensaver utilizes a multi-tiered performance setting to balance visual fidelity with thermal and framerate constraints on varying TV hardware.
    - **High (Level 2):** Full fidelity. Uses maximum sample counts in the fragment shader for blur loops and rendering passes.
    - **Balanced (Level 1) - Default:** Reduces the sampling fidelity slightly in the shader to maintain a solid 60fps on standard Google TV hardware (like a Chromecast with Google TV) while preserving aesthetic intent.
    - **Fast (Level 0):** Severely limits blur samples and rendering overhead. Designed for low-end Android TV panels or legacy boxes.

### **Typography & HUD Information (`StealBanner`)**
- **Track HUD:** If `Show Info Banner` is enabled, the screensaver displays the active track name, venue, and date dynamically.
- **Granular Spacing Controls:** The screensaver features completely independent typographic controls to fine-tune text readability in motion.
    - **Track Letter Spacing (`oilTrackLetterSpacing`):** Specifically adjusts the tracking of the central track title ring.
    - **Track Word Spacing (`oilTrackWordSpacing`):** specifically adjusts the spacing between words on the track title ring.
    - These are decoupled from the general banner UI, allowing users to dial in perfect legibility against the chaotic generative background.

---

## 2. Screensaver Settings Reference

To keep the UI consistent, the following settings (prefixed with `oil` internally) dictate the visualizer's state. They are documented here in the order they appear in the TV Settings UI (`tv_screensaver_section.dart`):

1. **Use Generative Screensaver** (`useOilScreensaver`): Master toggle for the entire Steal Your Face visualizer.
2. **Screensaver Time** (`idleTimeout`): The inactivity duration required before triggering (not an `oil` setting directly, but governs the threshold).
3. **Performance Mode** (`oilPerformanceLevel`): Balances shader fidelity. 0 = Fast, 1 = Balanced, 2 = High.
4. **Color Palette** (`oilPalette`): Selects the active base color range (e.g., Psychedelic, Acid Green, Ocean).
5. **Cycle Palettes** (`oilPaletteCycle`): Automatically transitions between color palettes over time.
6. **Cycle Duration** (`oilPaletteTransitionSpeed`): How fast the palette morphs during a cycle.
7. **Flow Speed** (`oilFlowSpeed`): Multiplier for the Lissajous mathematical path sweeping the logo around the screen.
8. **Pulse Intensity** (`oilPulseIntensity`): How aggressively the glow and halo scale with time (independent of audio).
9. **Heat Drift** (`oilHeatDrift`): Wavy distortion effect applied to the UV coordinates of the underlying logo texture.
10. **Translation Smoothing** (`oilTranslationSmoothing`): Lerp factor for orbital camera tracking (0.0 = instant, 1.0 = heavy drag).
11. **Orbit Drift** (`oilOrbitDrift`): Multiplier for the amplitude of the Lissajous curve the logo traces.
12. **Enable Audio Reactivity** (`oilEnableAudioReactivity`): Hooks into native Android Visualizer to drive beat detection and graphing.
13. **Audio Graph Mode** (`oilAudioGraphMode`): `off`, `corner` (9-band with text), or `circular` (8-band orbiting logo).
14. **Audio Graph Sensitivity** (`oilBeatSensitivity`): Determines the threshold required to trigger a "BEAT" spike and pulse.
15. **Enable HUD** (`oilShowInfoBanner`): Toggles the textual track information.
16. **HUD Display Mode** (`oilBannerDisplayMode`): `ring` (orbiting the logo) or `flat` (stacked block text).
17. **Font Family** (`oilBannerFont`): Selects the typeface for the HUD (e.g., Rock Salt, Roboto).
18. **Track Word Spacing** (`oilTrackWordSpacing`): Granular control for HUD word spacing.
19. **Track Letter Spacing** (`oilTrackLetterSpacing`): Granular control for HUD letter kerning.
20. **Logo Scale** (`oilLogoScale`): Overall sizing multiplier for the center Steal Your Face graphic.
21. **Blur Amount** (`oilBlurAmount`): Initial blur factor applied across the fragment shader. 
22. **Logo Trail Slices** (`oilLogoTrailSlices`): Number of ghost copies rendered behind the primary moving logo.
23. **Logo Trail Length** (`oilLogoTrailLength`): The time/distance offset between each ghost slice.
24. **Logo Trail Intensity** (`oilLogoTrailIntensity`): Opacity/Blend strength of the ghosting trail.
25. **Flat Text Proximity** (`oilFlatTextProximity`): Controls how close the block text renders to the image when in `flat` mode.
26. **Line Spacing** (`oilFlatLineSpacing`): Multiplier for line heights in `flat` mode.

---

## 2. Platform Exclusivity & Restrictions

- **Strict TV Exclusivity:** The screensaver is **walled off and exclusively available on the TV UI**. It will not trigger, and its settings are completely hidden, on native mobile apps or the web PWA. (Any previous logic relating to Web fallbacks for this visualizer has been officially deprecated and excluded).
- **Native Host Caveat:** TV-only UI gating does **not** mean Android native integration is TV-app-local. Because the shipping Play artifact uses the shared Android package, native PCM/MediaProjection fixes may need corresponding changes in both Android app hosts even when the visible feature remains TV-exclusive.
- **Hardware WakeLock:** The screensaver invokes the `WakelockService` when launched. This prevents the TV's native OS from forcing a deep sleep, allowing the audio to continue playing and the visualizer to remain active for hours.
- **Haptics Disabled:** All haptic feedback is hard-disabled through `AppHaptics` as it serves no purpose on a TV remote.
- **Keyboard Handling:** Android TV directional pad and OK button inputs are treated as standard keyboard events. Pressing *any* button pops the overlay.

---

## 3. Known Limitations & Constraints

- **Graphical Overhead:** Real-time GLSL visualizers (like `steal.frag`) are computationally heavy. On cheaper Android TV hardware stacks, utilizing "High" performance mode can cause frame drops and thermal throttling. Users should be advised to keep the setting at "Balanced".
- **Audio Permission Boundaries:** The audio reactivity requires permission to record/capture the global audio mix (usually handled automatically by Android for the active session, but edge cases in custom TV ROMs may block the visualizer).

---

## 4. Future Plans & Roadmap

### **1. TV-Specific Optimization Pass**
- Establish a strict "TV Safe Frame" border to ensure text renders correctly across different overscan settings on older TVs.
- Implement adaptive downgrading: If the app detects continuous frame drops below 30 FPS while the visualizer runs, gracefully step down `oilPerformanceLevel` from High to Balanced automatically.

### **2. Enhanced Media Controls Overlay**
- When the user presses "Pause/Play", "Next", or "Prev" via a physical remote media key, intercept the command without destroying the screensaver route. Display a temporary, minimal media HUD over the screensaver for 3 seconds before fading out, maintaining the "party mode" vibe.

### **3. Screensaver "Daydream" OS Integration**
- Investigate Android TV `DreamService`. Currently, the screensaver operates firmly inside the app. The ultimate goal is to register the `StealVisualizer` as a system-wide Android TV Daydream target, meaning the user can see the GDAR visuals even if the app is backgrounded.

