# GDAR Audio Engine Design Specification (Web UI / PWA)

> [!IMPORTANT]
> This specification applies **ONLY** to the Web UI / PWA builds. It does **NOT** apply to Android, Google TV, or other native builds.

This document serves as the source of truth for the web-based audio engine architecture and prevents unauthorized changes to stable components.

## 1. Engine Architecture & Settings

The engines are listed here in the same order as they appear in the UI selection menu:

| Option | Engine Type | Platform Intent | Key Benefit |
| :--- | :--- | :--- | :--- |
| **Web Audio** | [1] Gapless | **Desktop** | Sample-accurate 0ms gaps, high performance. |
| **HTML5** | [2] HTML5 | **PWA / Mobile Web** | Standard choice; most robust against background throttling. |
| **Standard** | [3] Native | Backup / Legacy | High compatibility, standard browser behaviors. |
| **Passive** | [4] Passive | Minimalist | Single-element streaming, lowest resource usage. |
| **Hybrid** | [5] Orchestrator | **Universal / Gapless** | Orchestrates HTML5 [2] and Web Audio [1] for background gaps. |

### [1] Web Audio (Gapless / `gapless_audio_engine.js`)
- **Status**: REFINING.
- **Role**: High-performance 0ms sample-accurate gapless playback. Primary for **Desktop** use.
- **Settings**: 
  - `web_prefetch_seconds`: Buffer ahead duration for current/next track.
  - `track_transition_mode`: Support for `gapless`, `crossfade` (0-10s), and `gap`.
- **Constraint**: Must report real-time fetch progress for `currentTrackBuffered` and `nextTrackBuffered`. MUST preserve decoded cache for instant seeking.

### [2] HTML5 (Gapless-ish / `html5_audio_engine.js`)
- **Status**: **STABLE**.
- **Role**: The standard choice and primary fallback for **Web UI / PWA**.
- **Settings**:
  - `track_transition_mode`: Support for `gapless` (dual-element swap) and `gap`. **NO CROSSFADE.**
- **Constraint**: DO NOT refactor to `ReadableStream` fetching; it breaks the engine's internal state. Must maintain the exact HTML5 `Track` and `Queue` structure.

### [3] Standard (Native / `just_audio`)
- **Status**: STABLE.
- **Role**: Conservative fallback using standard browser/native capabilities.
- **Settings**: All managed via standard `just_audio` backend. 

### [4] Passive (Single Element / `passive_audio_engine.js`)
- **Status**: STABLE.
- **Role**: Minimal, single `<audio>` element streaming for maximum simplicity.
- **Settings**: None.

### [5] Hybrid (Orchestrator / `hybrid_audio_engine.js`)
- **Status**: **STABLE / RECOMMENDED**.
- **Role**: The primary engine for high-quality gapless playback that **lasts**. It improves upon the standalone HTML5 engine [2] by orchestrating a seamless transition from "Instant Start" (HTML5) to "High Quality" (Web Audio).
- **Startup Sequence**:
  - Always starts playback using the **HTML5 Engine [2]** for 0ms initial latency.
  - Automatically hands off to **Web Audio [1]** as soon as the track is decoded/buffered to guarantee true 0ms gapless transitions for the remainder of the session.
- **Fallback Logic (The Escape Hatch)**:
  - **Stall Recovery**: If Web Audio [1] is stalled (buffering) for more than **5 seconds**, the engine automatically swaps to the **HTML5 Engine [2]** at the exact current position to resume playback.
  - **Survival Tricks**: Uses `video` or `heartbeat` tricks to keep the Web Audio engine alive in the background; HTML5 is only a fallback for network/resource failure, not a default background mode.
- **Auto-Restore**:
  - If the engine is currently driving playback via **HTML5 [2]** (e.g., following a stall), it **MUST NOT** attempt to restore to Web Audio immediately upon returning to the foreground.
  - Restoration to Web Audio is deferred until the **next track boundary** (handoff), ensuring stable playback of the current track regardless of visibility changes.
- **Resource Suspension Policy**:
  - If the OS forces a suspension of the audio context (survival failure), the engine **MUST NOT** auto-resume playback upon returning to the foreground.
  - The engine must report the state `suspended_by_os` to the UI to trigger a user-facing notification (Snackbar).
  
#### 1.1 Optimization for Persistent Gapless
To achieve "Instant Start" + "Persistent Gapless" in the background, the following configuration is REQUIRED:
- `handoffMode: 'immediate'` (Swaps to Web Audio as soon as decoded. Resolves UI sync issues by quickly transitioning to the foreground before track boundaries).
- `backgroundMode: 'video'` (Keeps the Web Audio context alive in the background).

> [!NOTE]
> The Hybrid engine uses its own isolated background processor (`hybrid_html5_engine.js`), entirely separate from the global HTML5 engine [2]. This isolation ensures that aggressive `syncState` and `gotoTrack` commands during handoffs do not corrupt the global HTML5 state, safely catching `null` tracks during rapid foreground/background transitions.

This ensures the user gets the speed of HTML5 for the initial hit, but the precision of Web Audio for the remainder of the show, even with the screen off.

## 2. Universal Governance Rules

1.  **Isolation Doctrine**: Engines [1] through [4] must operate entirely independently of each other. They must remain completely unaware of the Hybrid orchestrator [5]. Any rapid swaps, fast-forwards, or destructive pauses commanded by the Hybrid engine [5] must be handled by its own structurally isolated workers (e.g., `hybrid_html5_engine.js`), preserving the integrity and state of the standalone global engines.
2.  **Change Control**: All changes to **Web Audio [1]**, **HTML5 [2]**, **Standard [3]**, or **Passive [4]** require an explicit user request and approval via a detailed implementation plan.
3.  **Seeking**: If a track is already buffered/decoded in Web Audio, seeking MUST NOT trigger new network requests.
4.  **State Sync**: Dart (`SettingsProvider`) is the absolute source of truth for engine mode and settings.

## 3. Visibility & Background Behavior

To ensure the Hybrid engine [5] remains stable when the screen is off (e.g., during PWA use):

1.  **Background Startup**: If `play()` or `syncState()` is called while `document.hidden` is true, the engine MUST trigger `_gdarHeartbeat.startHeartbeat()` immediately *before* attempting to prime the underlying audio engines.
2.  **Hybrid Continuity**: The engine MUST NOT skip the "Instant Start" (HTML5 Engine [2]) phase just because the tab is hidden. Relying only on Web Audio for background starts is prohibited as it is more prone to suspension.
3.  **Heartbeat Priority**: Survival heartbeats (video/audio) are the primary mechanism for background stability. If `backgroundMode` is set to `heartbeat` or `video`, these MUST remain active throughout the duration of the background session.
