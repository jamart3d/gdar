# GDAR Web/PWA P1 QA Matrix

This matrix covers the critical testing scenarios for the P1 improvements (Stability, Recovery, and Background Playback).

## 1. Background Playback Stability (PWA)

| Scenario | Expected Behavior | Pass/Fail |
| :--- | :--- | :--- |
| **Tab Hidden (Desktop)** | Audio continues. "DFT" (Drift) remains < 0.3s. | |
| **PWA Hidden (Android)** | Audio continues. Engine mode remains Hybrid/Gapless unless network stalls. | |
| **iOS Safari Background** | Audio continues using HTML5 or Hybrid handoff. MediaSession controls remain active. | |
| **Timer Throttling (30m+)** | Audio continues. Worker heartbeat ("HB") remains 'OK'. | |
| **Lock Screen (Mobile)** | Show/Track metadata updates correctly on track change. | |

## 2. Recovery & Adaptive Budget

| Scenario | Expected Behavior | Pass/Fail |
| :--- | :--- | :--- |
| **Network Interruption (10s)** | Playing resumes from buffer. If buffer empty, recovers via HTML5 within 5s of reconnect. | |
| **Show Transition (Last Track)** | Next show is pre-queued 15s+ before end. Transition is gapless. | |
| **Background Hiding (Adaptive)** | Prefetch depth increases from 30s to 90s (V: HID). | |
| **Memory Pressure (Hidden)** | `_evictOldBuffers` aggressively cleans up old tracks to prevent OOM. | |

## 3. Boundary Sentinel & Predictive Selection

| Scenario | Expected Behavior | Pass/Fail |
| :--- | :--- | :--- |
| **Chronological Run (History)** | Playing 1977-05-08 then 1977-05-09 -> Next pre-queued show is 1977-05-11. | |
| **Stuck Prefetch (T-15s)** | If next track not scheduled at T-15s, "Boundary Sentinel" forces a fetch. | |
| **Dice Roll (TV Luck)** | Metadata syncs immediately. No "stale" metadata from previous show. | |

## 4. Platform Design (Fruit/TV)

| Scenario | Expected Behavior | Pass/Fail |
| :--- | :--- | :--- |
| **TV Screensaver** | Logo is visible (Shader working). No focus traps on exit. | |
| **Fruit Theme (Web)** | Backdrop blurs work. No Material 3 ripples or ripple effects. | |
| **Lock Screen/MediaSession** | Artwork (if supported) or stylized Placeholder appears. | |

## Success Criteria Checklist
- [ ] No audio gaps > 100ms on show transition.
- [ ] Recoveries from "stalled" states happen within 5 seconds.
- [ ] Browser "Hidden" state survives for 2+ hours without OS reclaim.
- [ ] Session History correctly predicts chronological next shows.
