# Web/PWA Audio Engine & Survival Analysis

## 1. Low Power Detection Logic (`LowPowerDetect`)
The system uses a synchronized heuristic across both Dart and JavaScript to categorize the device at runtime.

### Heuristic
` (Is Mobile UA) AND (Cores <= 2 OR (Cores <= 4 AND DevicePixelRatio < 2.0)) `

### Implementation Details
- **JavaScript Layer (`hybrid_init.js`)**: Defines `window._gdarDetectedAsLowPower` for diagnostic alignment.
- **Dart Layer (`packages/shakedown_core/lib/utils/web_perf_hint_web.dart`)**: The `isLikelyLowPowerWebDevice()` function drives the adaptive profile selection in `SettingsProvider`.

**Rationale**: This prevents modern high-end phones (e.g., iPhone 15, Pixel 8) from being flagged as low-power just because they are mobile, while correctly identifying budget Android devices and older iPads.

---

## 2. Audio Engine Profiles & Defaults
The `SettingsProvider` applies an **Adaptive Web Engine Profile** during the first run based on the device detection:

| Feature | **Low Power** (`Legacy` Profile) | **Standard/High Power** (`Modern` Profile) |
| :--- | :--- | :--- |
| **Primary Engine** | **HTML5 Audio Engine** | **Hybrid Audio Engine** (Web Audio) |
| **Background Strategy**| `video` (Immediate) | `heartbeat` (Escalated) |
| **Stability Level** | **Ultra-High** (Resilient to OS throttling) | **High** (Prioritizes 0ms gapless precision) |
| **Behavior** | Starts a hidden video loop *immediately* on tab-hide. | Starts an audio heartbeat; escalates to video after **60s** if still hidden. |

---

## 3. PWA Survival Analysis (Background Execution)
The "kill" chance depends heavily on the **Background Survival Strategy** active in the HUD/Settings.

### Survival Ratings
| Condition | Survival Rating | Explanation |
| :--- | :--- | :--- |
| **Foreground** | **100%** | PWA is active and visible. |
| **Background (PWA Installed)** | **95%** | Installed PWAs receive higher OS priority than browser tabs. The OS treats them as "first-class" apps. |
| **Background (Tab Mode)** | **70%** | Standard browser tabs are aggressively throttled (timers capped to 1Hz) or suspended after ~3-5 minutes. |
| **Strategy: `video`** | **98%** | **The Strongest Defense.** Uses a silent, 1x1 black MP4 loop. Most mobile OSs (iOS/Android) will not kill a process that is "playing video," effectively locking the app into memory. |
| **Strategy: `heartbeat`**| **85%** | Uses a silent WAV loop. Effective, but some aggressive Android skins (MIUI, Samsung "Deep Sleep") may ignore audio-only activity if the screen is off for a long duration. |

---

### Risks and Kill Conditions
1.  **RAM Pressure (Primary Risk)**: If you open a heavy app (like a game or high-res camera) while the PWA is in the background, the OS will kill the PWA to reclaim memory, regardless of heartbeats.
2.  **OS "Deep Sleep"**: Some Android devices have a "Battery Optimization" setting for specific apps. If enabled, the OS may ignore the heartbeat and kill the process after ~10-20 minutes of screen-off time.
3.  **Manual Dismissal**: Swiping the PWA out of the "Recents" task switcher kills it immediately.
4.  **Audio Interruptions**: If another app (YouTube, Phone call) takes **exclusive** audio focus, the PWA may be suspended if it doesn't gracefully handle the focus loss.
