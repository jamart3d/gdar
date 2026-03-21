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
| **3** | **Current Buffer** | _(removed)_ | `BUF` Value + fill bar + `PF` (Prefetch) |
| **4** | **Next Track** | _(removed)_ | `NX` Value + fill bar + `HF` (Handoff) |

## 2. The Sparkline Suite

The top row contains two real-time trend graphs. Each graph features a **tiny integrated label** in the lower-right corner for instant identification.

*   **DFT (Drift)**: Monitors high-resolution timing drift in worker ticks. Fluctuations here indicate thread contention or clock de-sync.
*   **HD (Headroom)**: Tracks how much silence or buffer remains before the engine starves. Positive values are critical for gapless performance.

### BUF and NX — Inline Bar Graphs

The `BUF` and `NX` value chips each contain an **embedded horizontal fill bar** (instead of a top-row sparkline). The bar fills from left to right proportionally against the configured prefetch window (`webPrefetchSeconds`, e.g. 30s or 60s). Colors: BUF uses teal, NX uses green.

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
| **DET** | Detect | — | Runtime profile (`L`: Low-power, `P`: PWA installed, `D`: Desktop, `W`: Browser). `L` is checked first — a low-power PWA shows `L`, not `P`. |
| **TX** | Transition | — | Track transition mode (`GLS`: Gapless, `XFD`: Crossfade, `GAP`: Gap). |
| **AE** | Active | **Indigo** (Survival+) | Core technology: `WA` (WebAudio), `H5` (HTML5), `VI` (Video). Suffixes: **`-New`** (Native/New), **`-Opt`** (Optimized/Old). A **`+`** indicates an active heartbeat helper and pulses in 220ms unison with the `BG` dots. |
| **ST** | Status | **Orange** (HFDN) | Internal state (`PLAY`, `STAL`, `SUSE`, `HFDN`). |
| **PS** | Process | **Orange** (BUF), **Green** (RDY) | Player Processing State (`LD`, `BUF`, `RDY`, `END`, `IDL`). |
| **PM** | Perf Mode | **Amber** (ON) | Performance Mode state. `ON` = visual effects disabled (set by low-power detection or Fruit first-run). `OFF` = full effects enabled and Liquid Glass active by default. |

### Controls & Presets (Interactive)
| Key | Label | Options | Purpose |
| :--- | :--- | :--- | :--- |
| **PF** | Prefetch | `30s`, `60s`, `G` | Toggle next-track lookahead window. `G` = greedy (WebAudio mode). Default is `60s` when handoff mode is `BND`, `30s` otherwise. |
| **HF** | Handoff | `IMM`, `BUF`, `BND`, `OFF` | Control when Hybrid engine swaps from H5 to WA. Default for modern profile is `BND` (boundary). |
| **BG** | Background | `HBT`, `VID`, `H5`, `NONE` | Set the survival strategy for hidden browser tabs. `HBT` auto-escalates to `VID` after 60s on mobile. |
| **STB** | Background Mode | `STB`→Compatible, `BAL`→Balanced, `MAX`→Gapless | Named preset bundles for the engine config. Compatible = best longevity, Gapless = best quality. |

## 4. Background Performance Monitoring

### The BG Chip
The **BG (Background)** chip is the primary monitor for tab survival. 
*   **Heartbeat Pulse**: Contains three horizontal indicators:
    *   **RED**: Heartbeat required by architecture but currently **Inactive**. High risk of OS suspension.
    *   **ORANGE**: Heartbeat not required (tab is currently visible).
    *   **GREEN**: Heartbeat **Active and Pulsing**. Successfully preventing tab sleep.
*   **Synchronized Heartbeat Pulse**: When a survival strategy (`HBT`, `VID`) is active, the engine enters a "shielded" state. This is visualized via a **unified pulse**:
    *   **Heartbeat Dot**: Flashes Green/Red in the `BG` chip.
    *   **Survival Marker**: A **`+`** symbol appears in the `AE` chip.
    *   **Perfect Sync**: Both indicators fade in/out together (220ms duration) to signal they are driven by the same internal clock.
*   **Survival Highlight**: When active, the **AE** chip background turns **Indigo** for high visibility.
*   **60s Escalation (mobile only)**: When `BG=HBT` and `isLikelyLowPowerWebDevice()` is true, a 60-second timer starts on tab-hide. If the tab is still hidden and playing at expiry, the engine automatically escalates from audio heartbeat (`HBT`) to video heartbeat (`VID`). The timer is cleared immediately on tab-show. Watch the `SHD` chip for escalation state.

## 5. Session Health Chips

Four computed chips that synthesise multiple raw signals into a single at-a-glance status.

### SHD — Session Shield
Summarises whether the current playback session is protected against OS suspension while hidden.

| Value | Color | Meaning |
| :--- | :--- | :--- |
| `VIS` | — | Tab is foreground — no background survival needed |
| `OK` | **Green** | Heartbeat active and pulsing — session shielded |
| `SOFT` | **Amber** | Background strategy active but heartbeat not yet pulsing — watch on mobile |
| `RISK` | **Orange** | Heartbeat needed but not running — OS may suspend soon |
| `DEAD` | **Red** | No survival strategy configured — tab will be killed in background |
| `--` | — | Not playing |

### GAP — Gapless Readiness
Shows whether the next-track buffer is ready for a gapless handoff at the track boundary.

| Value | Color | Meaning |
| :--- | :--- | :--- |
| `RDY` | **Green** | Next track buffered — gapless handoff expected |
| `WAIT` | **Cyan** | Next track prefetching — not yet ready |
| `LOW` | **Orange** | Handoff approaching, next buffer low — gap likely |
| `MISS` | **Red** | Handoff window reached with insufficient buffer — gap will occur |
| `OFF` | — | Gapless handoff disabled (`HF=OFF`) |
| `--` | — | No next-track prefetch in progress |

### BGT — Background Time
Cumulative time the tab has been hidden while playing this session. Accumulates across multiple background/foreground cycles. Resets on page reload. Text turns **light blue** when non-zero.

### PM — Performance Mode
Shows the current `performanceMode` state.

| Value | Color | Meaning |
| :--- | :--- | :--- |
| `ON` | **Amber** | Performance mode active — visual effects (glow, RGB, Liquid Glass) disabled |
| `OFF` | — | Full effects enabled; Liquid Glass is on by default for capable devices |

`ON` is set by: low-power device detection on first run, Fruit theme first-switch, or user toggle.

---

## 6. System Messaging & Signal Logic

The bottom row provides high-priority feedback via the **SIG** (Signal) and **MSG** (Message) fields.

*   **SIG (Signal)**:
    *   `ISS` (**Red**): **Issue** - Critical playback error or stall requiring attention.
    *   `NTF` (**Orange**): **Notification** - Transient system update (clears after 8s).
    *   `AGT` (**Cyan**): **Agent** - Status update from the Hybrid orchestrator.
*   **MSG (Message)**:
    *   **Marquee**: Text over 30 characters automatically scrolls.
    *   **Manual Clear**: Tapping the `MSG` chip clears the active issue and resets the signal.

## 7. HUD Lifecycle
*   **Enablement**: Requires `SettingsProvider.showDevAudioHud` = true and `kIsWeb`.
*   **Data Source**: Driven by a high-frequency (50ms) stream from `AudioProvider`.
*   **Precision Alignment**: All performance values are width-locked to **84px** to ensure stable vertical alignment with the graph columns, preventing UI "pop" during value changes.
