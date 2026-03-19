# DevAudioHud: Advanced Diagnostic Interface

The `DevAudioHud` is a specialized, ultra-high-density diagnostic overlay used to monitor the health and performance of the custom Web Audio engines in real-time.

## 1. Visual Architecture

The HUD is organized into a three-tier stacked layout designed for vertical alignment of related telemetry.

### Unified Performance Columns
To ensure a stable "precision-shave" look, the performance chips are fixed at **84px** width. This creates vertical columns where the graph data and the numeric data perfectly align:

| Column | Metric | Graph (Top Row) | Value Chip (Middle Row) |
| :--- | :--- | :--- | :--- |
| **1** | **State Drift** | `DFT` Sparkline | `DFT` Value |
| **2** | **Headroom** | `HD` Sparkline | `HD` Value |
| **3** | **Current Buffer** | `BUF` Sparkline | `BUF` Value + `PF` (Prefetch) |
| **4** | **Next Track** | `NX` Sparkline | `NX` Value + `HF` (Handoff) |

## 2. The Sparkline Suite

The top row contains four real-time trend graphs. Each graph features a **tiny integrated label** in the lower-right corner for instant identification.

*   **DFT (Drift)**: Monitors high-resolution timing drift in worker ticks. Fluctuations here indicate thread contention or clock de-sync.
*   **HD (Headroom)**: Tracks how much silence or buffer remains before the engine starves. Positive values are critical for gapless performance.
*   **BUF (Buffer)**: Real-time visualization of the current track's buffer growth/consumption.
*   **NX (Next)**: Lookahead visualization for the pre-buffered next track (crucial for verifying gapless handoffs).

## 3. Field Reference (The HUD Dictionary)

Each chip represents a specific state or metric. Tapping an interactive chip (indicated by an active border) opens an adjustment menu.

### Performance & Timing
| Key | Label | Color Cues | Meaning |
| :--- | :--- | :--- | :--- |
| **DFT** | Drift | — | JS Engine Tick Drift (seconds). Lower is better. |
| **HD** | Headroom | **Red** (<0s), **Orange** (<5s) | Buffer minus Position. Positive values prevent gaps. |
| **BUF** | Buffer | — | Current track data in memory (MB). |
| **NX** | Next | — | Next track prefetch progress (MB). |
| **V** | Visibility | — | App state (`VIS`: Foreground, `HID`: Background) + duration. |

### Engine & Capability
| Key | Label | Color Cues | Meaning |
| :--- | :--- | :--- | :--- |
| **ENG** | Engine | — | Configured Engine Mode (`HYB`, `WBA`, `H5`, `STD`, `AUT`). |
| **DET** | Detect | — | Hardware Profile (`D`: Desktop, `M`: Mobile, `P`: PWA, `W`: Web). |
| **AE** | Active | **Indigo** (Survival+) | Core technology: `WA` (WebAudio), `H5` (HTML5), `VI` (Video). Suffixes: **`-New`** (Native/New), **`-Opt`** (Optimized/Old). A **Standard +** indicates an active heartbeat helper. The `+` pulses in perfect 220ms unison with the `BG` dots. |
| **ST** | Status | **Orange** (HFDN) | Internal state (`PLAY`, `STAL`, `SUSE`, `HFDN`). |
| **PS** | Process | **Orange** (BUF), **Green** (RDY) | Player Processing State (`LD`, `BUF`, `RDY`, `END`, `IDL`). |

### Controls & Presets (Interactive)
| Key | Label | Options | Purpose |
| :--- | :--- | :--- | :--- |
| **PF** | Prefetch | `30s`, `60s`, `G` | Toggle next-track lookahead window. |
| **HF** | Handoff | `IMM`, `BUF`, `BND`, `OFF` | Control when Hybrid engine swaps from H5 to WA. |
| **BG** | Background | `HBT`, `VID`, `H5`, `NONE` | Set the survival strategy for hidden browser tabs. |
| **STB** | Stability | `STB`, `BAL`, `MAX` | Apply pre-defined engine tuned profiles. |

## 4. Background Performance Monitoring

### The BG Chip
The **BG (Background)** chip is the primary monitor for tab survival. 
*   **Heartbeat Pulse**: Contains three horizontal indicators:
    *   **RED**: Heartbeat required by architecture but currently **Inactive**. High risk of OS suspension.
    *   **ORANGE**: Heartbeat not required (tab is currently visible).
    *   **GREEN**: Heartbeat **Active and Pulsing**. Successfully preventing tab sleep.
*   **Synchronized Heartbeat Pulse**: When a survival strategy (`HBT`, `VID`) is active, the engine enters a "shielded" state. This is visualized via a **unified pulse**:
+    *   **Heartbeat Dot**: Flashes Green/Red in the `BG` chip.
+    *   **Survival Marker**: A standard **`+`** symbol appears in the `AE` chip.
+    *   **Perfect Sync**: Both indicators fade in/out together (220ms duration) to signal they are driven by the same internal clock.
+*   **Survival Highlight**: When active, the **AE** chip background turns **Indigo** for high visibility.

## 5. System Messaging & Signal Logic

The bottom row provides high-priority feedback via the **SIG** (Signal) and **MSG** (Message) fields.

*   **SIG (Signal)**:
    *   `ISS` (**Red**): **Issue** - Critical playback error or stall requiring attention.
    *   `NTF` (**Orange**): **Notification** - Transient system update (clears after 8s).
    *   `AGT` (**Cyan**): **Agent** - Status update from the Hybrid orchestrator.
*   **MSG (Message)**:
    *   **Marquee**: Text over 30 characters automatically scrolls.
    *   **Manual Clear**: Tapping the `MSG` chip clears the active issue and resets the signal.

## 6. HUD Lifecycle
*   **Enablement**: Requires `SettingsProvider.showDevAudioHud` = true and `kIsWeb`.
*   **Data Source**: Driven by a high-frequency (50ms) stream from `AudioProvider`.
*   **Precision Alignment**: All performance values are width-locked to **84px** to ensure stable vertical alignment with the graph columns, preventing UI "pop" during value changes.
