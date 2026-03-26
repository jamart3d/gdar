# GDAR Web Playback Decision Tree (First Run)

To provide an optimal "out-of-the-box" experience without requiring manual calibration, GDAR implements a hardware-aware decision tree that automatically selects the appropriate audio engine and stability presets during the first-run initialization of the Web UI (Fruit style / PWA).

## 1. Decision Logic

The initialization logic is encapsulated in `SettingsProvider._resetWebPlaybackSettings()`. It evaluates the `WebRuntimeProfile` (D, P, W, L) to assign a `HiddenSessionPreset`.

| Chip | Profile | Background Mode (Preset) | Hybrid Handoff Mode | Background Survival Strategy | Strategy Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **[D]** | **Desktop** | Gapless | Mid | Off | Full immersion; uses buffered handoff for gapless reliability. Gated to Balanced on Desktop Safari. |
| **[P]** | **PWA** | Balanced | Mid | HBeat | Energy-efficient background survival for apps. |
| **[W]** | **Web (Mobile)** | Balanced | Mid | HBeat | Standard mobile browser support. Gated to Compatible on Safari. |
| **[L]** | **Low-Power** | Compatible | Off | HTML5 | Maximum resource preservation and H5 background hack. |

## 2. UI Preset & HUD Chip Mapping

The UI labels in the **Settings > Audio Engine** menu map directly to the `HiddenSessionPreset` and the real-time HUD chips.

### Gapless (Performance)
- **UI Background Mode**: Gapless
- **UI Handoff Mode**: Mid
- **UI Survival Strategy**: Off
- **HUD STB Chip**: `STB:MAX`
- **HUD ENG Chip**: `ENG:HYB` (Hybrid)
- **HUD AE Chip**: Starts as `AE:H5`, then reports active engine (`AE:WA` or `AE:H5`)
- **Description**: Prioritizes sample-accurate transitions. Crucially, the first track always starts using the HTML5 engine (`AE:H5`) to ensure immediate playback. While running in Hybrid mode, the AE chip then dynamically reports transitions to Web Audio for subsequent gapless precision.

### Balanced (Standard)
- **UI Background Mode**: Balanced
- **UI Handoff Mode**: Mid
- **UI Survival Strategy**: HBeat
- **HUD STB Chip**: `STB:BAL`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD AE Chip**: Typically `AE:H5`
- **Description**: The standard profile for modern mobile/PWA. Balances gapless performance with battery efficiency.

### Compatible (Efficiency)
- **UI Background Mode**: Compatible
- **UI Handoff Mode**: Off
- **UI Survival Strategy**: HTML5
- **HUD STB Chip**: `STB:STB`
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:NONE`
- **Description**: Designed for legacy/low-power hardware. Reduces overhead by disabling complex handoffs and using simpler survival hacks.

## 3. HUD Chip Reference Guide

- **D (Device Profile)**: The detected hardware/runtime profile.
  - `D:D`: Desktop | `D:P`: PWA | `D:W`: Web | `D:L`: Low-Power
- **STB (Stability Preset)**: Displays the current active preset (`MAX`, `BAL`, `STB`).
- **ENG (Engine Mode)**: Routing logic strategy (`HYB` = Hybrid, `WA` = Forced Web Audio).
- **AE (Audio Element)**: The definitive report of the active engine (`WA` = Web Audio, `H5` = HTML5).
- **HF (Handoff)**: Transition strategy (`BUF` = Buffered/Mid, `IMM` = Immediate, `NONE` = Off).
- **BG (Background Mode)**: Strategy to prevent tab sleeping (`OFF`, `H5`, `HTB` = Heartbeat, `VID` = Video).
- **BGT (Background Time)**: Reports the total accumulated time the app has been hidden or in the background. Useful for debugging OS-level throttling.
- **PM (Performance Mode)**: Indicates if high-precision mode is engaged.
  - `PM:ON`: High-precision active. Note: Engages "Simple Theme" by default to minimize UI thread interference.
  - `PM:OFF`: Standard UI/Engine behavior.
- **NET (Network TTFB)**: Reports Time to First Byte in ms. (Active during `AE:WA` usage).
- **TX (Transition Mode)**: Reports the track transition logic currently in queue.
- **GAP (Gapless Readiness)**: Indicates if the engine logic is primed for a gapless transition.
- **LG (Last Gap)**: Reports the measured silence between the last two tracks in ms. Ideally 0ms.

## 4. Detection Mechanisms

The detection relies on non-intrusive browser heuristics:

*   **Low-Power Web Device**: Detected via `isLikelyLowPowerWebDevice()`. Flags devices with <= 2 cores, or <= 4 cores with low DPI.
*   **Safari Web**: Parses the User Agent to identify Safari-specific rendering engines.
*   **Mobile Web**: Identifies mobile viewports and specific User Agent strings.

## 5. Implementation Context

These settings are applied during:
- The initial launch of the Web app.
- A theme style reset (e.g., switching from Android to Fruit for the first time).

Settings are persisted to `SharedPreferences` but remain user-adjustable through the **Settings > Audio Engine** menu.
