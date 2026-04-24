# Web/PWA Audio Engine & Survival Analysis

## 1. Low Power Detection Logic (`LowPowerDetect`)
The system uses a synchronized heuristic across both Dart and JavaScript to categorize the device at runtime.

### Heuristic
`(Is Mobile UA) AND (Cores <= 2 OR (Cores <= 4 AND DevicePixelRatio < 2.0))`

### Implementation Details
- **JavaScript Layer (`hybrid_init.js`)**: Defines `window._gdarDetectedAsLowPower` for diagnostic alignment.
- **Dart Layer (`packages/shakedown_core/lib/utils/web_perf_hint_web.dart`)**: The `isLikelyLowPowerWebDevice()` function drives the adaptive profile selection in `SettingsProvider`.

**Rationale**: This prevents modern high-end phones (e.g., iPhone 15, Pixel 8) from being flagged as low-power just because they are mobile, while correctly identifying budget Android devices and older iPads.

---

## 2. Audio Engine Profiles & Defaults
The `SettingsProvider` applies an **Adaptive Web Engine Profile** during the first run based on the device detection.

| Feature | Low Power (`Legacy` Profile) | Standard/High Power (`Modern` Profile) |
| :--- | :--- | :--- |
| **Primary Engine** | **HTML5 Audio Engine** | **Hybrid Audio Engine** |
| **Background Strategy** | `video` (Immediate) | `heartbeat` (Escalated) |
| **Stability Level** | **Ultra-High** (Resilient to OS throttling) | **High** (Prioritizes gapless precision while visible) |
| **Behavior** | Starts a hidden video loop immediately on tab-hide. | Starts an audio heartbeat; escalates to video after 60s if still hidden. |

---

## 3. PWA Survival Analysis (Background Execution)
The relative "kill" resistance depends on the active background strategy and hidden-session profile.

### Survival ranking
| Rank | Config | Explanation |
| :---: | :--- | :--- |
| 1 | `hybrid` + `chargingGapless` + `video` | Strongest overall background survival with the best foreground restore behavior when charging. |
| 2 | `hybrid` + `batterySaver` + `video` | Battery-safe hybrid path with strong hidden-tab survival. |
| 3 | `hybrid` + `heartbeat` | Keeps the AudioContext warm, but mobile browsers can still suspend it. |
| 4 | `webAudio` + no survival | Best visible-only gapless, but no hidden playback survival path. |

### Risks and Kill Conditions
1. **RAM Pressure (Primary Risk)**: If you open a heavy app (like a game or high-res camera) while the PWA is in the background, the OS can kill the PWA to reclaim memory.
2. **OS "Deep Sleep"**: Some Android devices have a Battery Optimization setting for specific apps. If enabled, the OS may ignore the keepalive strategy and kill the process after prolonged screen-off time.
3. **Manual Dismissal**: Swiping the PWA out of the Recents task switcher kills it immediately.
4. **Audio Interruptions**: If another app (YouTube, a phone call) takes exclusive audio focus, the PWA may be suspended if it doesn't handle the focus loss cleanly.
