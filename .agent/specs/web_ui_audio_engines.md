# GDAR Audio Engine Design Specification (Web UI / PWA)

> [!IMPORTANT]
> This specification applies **ONLY** to the Web UI / PWA builds. It does **NOT** apply to Android, Google TV, or other native builds.

This document serves as the source of truth for the web-based audio engine architecture and prevents unauthorized changes to stable components.

## 1. Engine Architecture & Settings

The engines are listed here in the same order as they appear in the UI:

### [1] Web Audio (Gapless / `gapless_audio_engine.js`)
- **Status**: REFINING.
- **Role**: High-performance 0ms sample-accurate gapless playback.
- **Settings**: 
  - `web_prefetch_seconds`: Buffer ahead duration for current/next track.
  - `track_transition_mode`: Support for `gapless`, `crossfade` (0-10s), and `gap`.
- **Constraint**: Must report real-time fetch progress for `currentTrackBuffered` and `nextTrackBuffered`. MUST preserve decoded cache for instant seeking.

### [2] Relisten (HTML5 / Gapless-ish / `html5_audio_engine.js`)
- **Status**: **STABLE (Relisten Port)**.
- **Role**: Robust background fallback and pure HTML5 streaming for the user-facing "HTML5" engine setting.
- **Settings**:
  - `track_transition_mode`: Support for `gapless` (dual-element swap) and `gap`. **NO CROSSFADE.**
- **Constraint**: DO NOT refactor to `ReadableStream` fetching; it breaks the engine's internal state. Must maintain the exact Relisten `Track` and `Queue` structure.

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
- **Role**: The primary engine for high-quality gapless playback that **lasts**. It improves upon Relisten [2] by orchestrating a seamless transition from "Instant Start" (HTML5) to "High Quality" (Web Audio).
- **Startup Sequence**:
  - Always starts playback using **Relisten [2]** (HTML5) for 0ms initial latency.
  - Automatically hands off to **Web Audio [1]** as soon as the track is decoded/buffered to guarantee true 0ms gapless transitions for the remainder of the session.
- **Fallback Logic (The Escape Hatch)**:
  - **Stall Recovery**: If Web Audio [1] is stalled (buffering) for more than **5 seconds**, the engine automatically swaps to **Relisten [2]** (HTML5) at the exact current position to resume playback.
  - **Survival Tricks**: Uses `video` or `heartbeat` tricks to keep the Web Audio engine alive in the background; HTML5 is only a fallback for network/resource failure, not a default background mode.
- **Auto-Restore**:
  - If the engine is currently driving playback via **Relisten [2]** (e.g., following a stall), it **MUST NOT** attempt to restore to Web Audio immediately upon returning to the foreground.
  - Restoration to Web Audio is deferred until the **next track boundary** (handoff), ensuring stable playback of the current track regardless of visibility changes.
- **Resource Suspension Policy**:
  - If the OS forces a suspension of the audio context (survival failure), the engine **MUST NOT** auto-resume playback upon returning to the foreground.
  - The engine must report the state `suspended_by_os` to the UI to trigger a user-facing notification (Snackbar).
  
#### 1.1 Optimization for Persistent Gapless
To achieve "Instant Start" + "Persistent Gapless" in the background, the following configuration is REQUIRED:
- `handoffMode: 'immediate'` (Swaps to Web Audio as soon as decoded. Resolves UI sync issues by quickly transitioning to the foreground before track boundaries).
- `backgroundMode: 'video'` (Keeps the Web Audio context alive in the background).

> [!NOTE]
> The Hybrid engine uses its own isolated background processor (`hybrid_html5_engine.js`), entirely separate from the global Relisten engine [2]. This isolation ensures that aggressive `syncState` and `gotoTrack` commands during handoffs do not corrupt the global HTML5 state, safely catching `null` tracks during rapid foreground/background transitions.

This ensures the user gets the speed of HTML5 for the initial hit, but the precision of Web Audio for the remainder of the show, even with the screen off.

## 2. Universal Governance Rules

1.  **Isolation Doctrine**: Engines [1] through [4] must operate entirely independently of each other. They must remain completely unaware of the Hybrid orchestrator [5]. Any rapid swaps, fast-forwards, or destructive pauses commanded by the Hybrid engine [5] must be handled by its own structurally isolated workers (e.g., `hybrid_html5_engine.js`), preserving the integrity and state of the standalone global engines.
2.  **Change Control**: All changes to **Web Audio [1]**, **Relisten [2]**, **Standard [3]**, or **Passive [4]** require an explicit user request and approval via a detailed implementation plan.
3.  **Seeking**: If a track is already buffered/decoded in Web Audio, seeking MUST NOT trigger new network requests.
4.  **State Sync**: Dart (`SettingsProvider`) is the absolute source of truth for engine mode and settings.
