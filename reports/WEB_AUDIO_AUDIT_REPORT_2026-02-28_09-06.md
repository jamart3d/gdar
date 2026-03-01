# Web Audio Engine Audit - GDAR (Shakedown)
**Date**: 2026-02-28 09:06
**Status**: Post-Relisten Port & Background Survival Integration

## Overview
This audit reflects the massive architectural shift where the HTML5 engine was replaced with a strict port of the Relisten `gapless.cjs` logic, and the Hybrid engine was upgraded with "Survival Tier" background persistence.

---

## 1. Current Engine State (As of Feb 28)

### 1.1 HTML5 Engine (`html5_audio_engine.js`)
- **Status**: **STRICT RELISTEN PORT**
- **Architecture**: Employs the `Gapless.Queue` and `Gapless.Track` classes directly from the Relisten project.
- **Internal Hybridization**: It is no longer a simple `<audio>` tag switcher. It handles its own internal "Instant Start" to "Web Audio" handoff for every track.
- **Buffering Logic**: Uses a 25-second pre-load threshold and high-fidelity `requestAnimationFrame` polling.
- **Mobile Harmony**: Inherits Relisten's "Silent Prime" logic to bypass autoplay restrictions.

### 1.2 Hybrid Engine (`hybrid_audio_engine.js`)
- **Status**: **SURVIVAL OPTIMIZED**
- **Architecture**: A meta-orchestrator managing the handoff between the Relisten-style HTML5 engine and our custom Web Audio engine.
- **Web Worker Heartbeat**: The handoff decision clock now runs in `audio_scheduler.worker.js`. This is immune to main-thread throttling when the tab is hidden.
- **Silent Video Hack**: Now utilizes a 1x1 transparent silent video via `audio_heartbeat.js`. This forces the mobile OS to grant the tab "Active Video" priority, keeping the JS engine awake indefinitely.
- **Leak Protection**: Implements `attemptId` guards to prevent "runaway" handoff loops during rapid track skipping or seeking.

### 1.3 Gapless Engine (`gapless_audio_engine.js`)
- **Status**: **STABLE FOREGROUND**
- **Architecture**: Pure Web Audio renderer with sample-accurate scheduling.
- **Memory Management**: Aggressive PCM eviction (100MB buffer deletion) the instant a track ends.

---

## 2. Progress Reporting Requirements (New)
- **30s Threshold**: Both engines now strictly hide "Next Track" buffered progress until the current track has **30 seconds or less** remaining.
- **Reporting vs Loading**: Pre-loading still happens at the 25s (HTML5) or 30s (Web Audio) mark, but the UI reporting is decoupled to keep the interface clean during long play sessions.

---

## 3. Background Survival Rating

| Engine | Survival Tier | Gapless Quality | Best For... |
| :--- | :--- | :--- | :--- |
| **HTML5** | **Gold** | High (Relisten Standard) | General Mobile Use / Long Shows |
| **Hybrid** | **Platinum** | Sample-Accurate | Absolute Background Reliability + Precision |
| **Gapless** | **Silver/Gold** | Sample-Accurate | Desktop / Pure Web Audio Enthusiasts |
| **Passive** | **Indestructible** | 500ms Gaps | Extreme Low-Power / Emergency Playback |

---

## 4. Summary of Improvements (Feb 28)
1. [x] **Relisten Integration**: HTML5 engine now matches the industry standard for gapless web playback.
2. [x] **Video Heartbeat**: Solved the "Screen Off" mortality problem on iOS/Android.
3. [x] **Worker Handoff**: Decoupled engine transitions from unstable main-thread timers.
4. [x] **Handoff Guarding**: Eliminated potential CPU spikes from overlapping decode processes.
5. [x] **UI Polish**: Implemented the 30s reporting threshold for next-track progress.
