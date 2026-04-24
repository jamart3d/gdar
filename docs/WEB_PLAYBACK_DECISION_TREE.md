# GDAR Web Playback Decision Tree (First Run)

To provide an optimal "out-of-the-box" experience without requiring manual calibration, GDAR implements a hardware-aware decision tree that automatically selects the appropriate audio engine and stability presets during the first-run initialization of the Web UI (Fruit style / PWA).

Installed standalone PWA sessions start in Hybrid unless the device is low-power. Mobile browser tabs and low-power web devices use HTML5. Runtime power profiles then switch installed PWA sessions between battery-safe and charging-gapless playback without requiring a relaunch.

## 1. Decision Logic

`SettingsProvider._resetWebPlaybackSettings()` evaluates the `WebRuntimeProfile` (D, P, W, L) to assign the hidden-session preset. `WebPlaybackPowerProfile` is resolved separately by `_applyWebPlaybackPowerPolicy()` and the web charging-state listener.

| Chip | Profile | UI Power Mode | Hybrid Handoff Mode | Background Survival Strategy | Strategy Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **[D]** | **Desktop** | Gapless | Mid | Off | Full immersion; uses buffered handoff for gapless reliability. Gated to Balanced on Desktop Safari. |
| **[P]** | **Installed PWA** | Power Profile: Auto | Battery: Off + Video; Charging: Immediate + Video | Battery: HTML5-like Hybrid; Charging: WebAudio gapless | Installed PWA launches Hybrid so runtime power profiles can switch between long-session and gapless behavior without engine relaunch. |
| **[W]** | **Web (Mobile)** | Browser Tab | Off | HTML5 | Mobile browser tabs prioritize durable HTML5 playback over Hybrid/WebAudio handoff. |
| **[L]** | **Low-Power** | Battery Saver / Compatible | Off | HTML5 | Maximum resource preservation and HTML5 background fallback. |

Power profile resolution:
- `auto` + charging detected -> `chargingGapless`
- `auto` + battery or unknown -> `batterySaver`
- `custom` -> do not overwrite manual engine settings

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

### Battery Saver / Compatible
- **UI Power Mode**: Battery
- **UI Handoff Mode**: None
- **UI Survival Strategy**: Video
- **HUD STB Chip**: Current hidden-session preset (`STB:MAX`, `STB:BAL`, or `STB:STB`)
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:NONE`
- **HUD PWR Chip**: `PWR:BAT`
- **Description**: HTML5-like Hybrid for battery or unknown power state. Keeps background survival on video, disables hidden Web Audio, and avoids sleep prevention.

### Charging Gapless
- **UI Power Mode**: Charging
- **UI Handoff Mode**: Immediate
- **UI Survival Strategy**: Video
- **HUD STB Chip**: Current hidden-session preset (`STB:MAX`, `STB:BAL`, or `STB:STB`)
- **HUD ENG Chip**: `ENG:HYB`
- **HUD HF Chip**: `HF:IMM`
- **HUD PWR Chip**: `PWR:CHG`
- **Description**: Hybrid playback tuned for charging devices. Enables hidden Web Audio, prevents sleep, and restores gapless playback immediately when visible.

## 3. HUD Chip Reference Guide

- **D (Device Profile)**: The detected hardware/runtime profile.
  - `D:D`: Desktop | `D:P`: PWA | `D:W`: Web | `D:L`: Low-Power
- **STB (Stability Preset)**: Displays the current active preset (`MAX`, `BAL`, `STB`).
- **ENG (Engine Mode)**: Routing logic strategy (`HYB` = Hybrid, `WBA` = Web Audio).
- **AE (Audio Element)**: The definitive report of the active engine (`WA` = Web Audio, `H5` = HTML5).
- **HF (Handoff)**: Transition strategy (`BUF` = Buffered/Mid, `IMM` = Immediate, `NONE` = Off).
- **BG (Background Mode)**: Strategy to prevent tab sleeping (`OFF`, `H5`, `HRT` = Heartbeat, `VID` = Video).
- **PWR (Power Profile)**: Runtime power state (`BAT`, `CHG`, `CUS`).
- **HBB (Heartbeat Blocks)**: Number of blocked heartbeat attempts while hidden, or `--` when not measured.
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
