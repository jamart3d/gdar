# TV Screensaver UI Specification (GDAR)

This document outlines the current state, architecture, and future development plans for the TV Screensaver feature within the GDAR application. The screensaver uses a fully custom generative visualizer ("Steal Your Face") to prevent screen burn-in while maintaining the application's aesthetic.

## 1. Current State & Architecture

### **Core Trigger Mechanism**
- **Service:** `InactivityService` monitors user interaction across the app.
- **Trigger:** Activating after a default period (e.g., 5 minutes) of inactivity if the `useOilScreensaver` setting is enabled.
- **Guardrails:** When triggered, the screensaver (`ScreensaverScreen.show`) explicitly stops the `InactivityService` to prevent multiple hardware key events from stacking overlapping screensaver routes. Once dismissed, the service restarts.
- **Dismissal:** Any `KeyDownEvent` captured by a global `HardwareKeyboard` handler pops the route and returns the user to the underlying application state.

### **Visuals & Audio Reactivity (`StealVisualizer`)**
- **Configuration:** Driven by `StealConfig`, which provides over 35 parameters controlling flow speed, palettes, film grain, translation smoothing, and audio beat sensitivity.
- **Audio Reactor:** Integrates smoothly via `AudioReactorFactory`. When audio reactivity is enabled, it bridges the active `AudioProvider` (or Android Audio Session ID) to map decibel/frequency bands directly to the visualizer's pulse and heat drift variables. 
- **Performance Mode:** Exposes an `oilPerformanceMode` which forces lower graphical overhead when on constrained devices (specifically forced `true` or heavily hinted when `deviceService.isTv` is active).

### **Information Overlay**
- **HUD:** If `Show Info Banner` is enabled, the screensaver passes the active track name, venue, and date dynamically to the `StealConfig`. 
- **Display Configurations:** Elements can be displayed in different formats (flat lines, orbital rings).

---

## 2. Platform Nuances & Restrictions

- **Strict TV Exclusivity:** The screensaver is **walled off and exclusively available on the TV UI**. It will not trigger on native mobile apps or the web PWA regardless of inactivity.
- **Hardware WakeLock:** The screensaver invokes the `WakelockService` when launched. This prevents the TV's native OS from forcing a deep sleep, allowing the audio to continue playing and the visualizer to remain active.
- **TV Execution:** All haptic feedback is hard-disabled through `AppHaptics`.
- **Keyboard Handling:** Android TV directional pad and OK button inputs are treated as standard keyboard events. Pressing *any* button pops the overlay.

---

## 3. Known Limitations & Constraints

- **Graphical Overhead:** Real-time visualizers can be computationally heavy. On cheaper Android TV hardware stacks, large blur radii and complex audio-reactive logic can cause frame drops and thermal throttling.
- **Web Limitations:** Audio reactivity relies heavily on native Android AudioSession IDs or `just_audio` specific hooks which are limited or spoofed as a fallback when `kIsWeb` is true.

---

## 4. Future Plans & Roadmap

### **1. TV-Specific Optimization Pass**
- Establish a strict "TV Safe Frame" border to ensure text renders correctly across different overscan settings.
- Implement adaptive downgrading. If the app detects continuous frame drops below 30 FPS while the visualizer runs, gracefully step down `StealConfig` parameters (e.g., turning off blur layers or lowering rasterization resolution).

### **2. Enhanced Media Controls Overlay**
- When the user presses "Pause/Play" via a physical remote, intercept the key command. Instead of immediately destroying the screensaver route, pass the play/pause command to the `AudioProvider` and display a temporary, minimal media HUD over the screensaver for 3 seconds before fading out.

### **3. Screensaver "Daydream" OS Integration**
- Investigate Android TV `DreamService`. Currently, the screensaver operates firmly inside the app. The ultimate goal is to register the `StealVisualizer` as a system-wide Android TV Daydream target, meaning the user can see the GDAR visuals even if the app is backgrounded.

### **4. Design Aesthetic Integration**
- Unify the text overlay elements inside the screensaver with the broader app typography rules defined in the `web_ui_design_spec.md` and `tv_flow_audit`, ensuring font weights (`Inter`), spacing, and non-Material ripple logic apply to any interactive components overlaid on the visualizer.
- Remove older, heavier shadowing in favor of the new translucent structural styling currently used in the main interface.
