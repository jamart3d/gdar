# GDAR Web Playback Decision Tree (First Run)

To provide an optimal "out-of-the-box" experience without requiring manual calibration, GDAR implements a hardware-aware decision tree that automatically selects the appropriate audio engine and stability presets during the first-run initialization of the Web UI (Fruit style / PWA).

## 1. Decision Logic

The initialization logic is encapsulated in `SettingsProvider._resetWebPlaybackSettings()`. It evaluates the `WebRuntimeProfile` (D, P, W, L) to assign a `HiddenSessionPreset`.

| Chip | Profile | Target Preset | Engine Mode | Handoff | Strategy Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **[D]** | **Desktop** | `maxGapless` | `Web Audio` | `immediate` | Full immersion. *Gated to `balanced` on Desktop Safari.* |
| **[P]** | **PWA** | `balanced` | `Hybrid` | `buffered` | Energy-efficient background survival for apps. |
| **[W]** | **Web (Mobile)** | `balanced` | `Hybrid` | `buffered` | Standard mobile browser support. *Gated to `stability` on Safari.* |
| **[L]** | **Low-Power** | `stability` | `Hybrid` | `buffered` | Maximum resource preservation and H5 background hack. |

## 2. Detection Mechanisms

The detection relies on non-intrusive browser heuristics:

*   **Low-Power Web Device**: Detected via `isLikelyLowPowerWebDevice()`. It flags devices with low hardware concurrency (<= 2 cores, or <= 4 cores with low DPI) as "budget" or "legacy" hardware.
*   **Safari Web**: Detected via `isSafariWeb()`. Parses the User Agent to identify Safari-specific rendering engines (excluding Chrome/Chromium on Mac).
*   **Mobile Web**: Detected via `isMobileWeb()`. Identifies mobile viewports and mobile-specific User Agent strings (`mobi`, `android`, `iphone`, `ipad`).

## 3. Implementation Context

These settings are applied during:
- The initial launch of the Web app (if no previous settings exist).
- A theme style reset (e.g., switching from Android to Fruit for the first time).

Settings are persisted to `SharedPreferences` but remain user-adjustable through the **Settings > Audio Engine** menu.

## 4. Key References

- `packages/shakedown_core/lib/providers/settings_provider.dart` (`_resetWebPlaybackSettings`)
- `packages/shakedown_core/lib/utils/web_perf_hint.dart` (Hardware heuristics)
- `.agent/specs/web_ui_audio_engines.md` (Engine behavior details)
