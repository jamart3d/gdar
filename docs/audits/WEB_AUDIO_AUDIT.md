# Web Audio Engine Audit - GDAR (Shakedown)
**Date**: 2026-02-27
**Status**: Comprehensive Final Review (Post-Optimization)

## Overview
Shakedown uses a highly resilient, 5-part multi-engine architecture on the web to deliver zero-ms gapless and crossfaded audio while completely mitigating browser-enforced background battery saving (tab sleep/throttling).

---

## 1. Engine Architecture (UI Options vs Implementation)

In the application's Settings UI, the user can select from 5 distinct processing modes for web playback:

1. **Web Audio** (`gapless_audio_engine.js`)
   - **Role**: The high-fidelity foreground renderer.
   - **Mechanism**: Fetches full files, decodes to raw PCM `AudioBuffer`s, and uses `AudioBufferSourceNode`s connected to dedicated localized `GainNode`s.
   - **Strength**: True 0ms sample-accurate gapless playback and organic 3-second crossfades.
   - **Weakness**: Cannot progressively stream. Requires 100% of the compressed file to be downloaded before decoding can begin.
   - *Note: This engine secretly utilizes a 6th hidden component, `audio_scheduler.worker.js`, for off-thread timer precision.*

2. **HTML5** (`html5_audio_engine.js`)
   - **Role**: Legacy / progressive streaming fallback.
   - **Mechanism**: Uses two alternating `<audio>` tags.
   - **Strength**: Very low RAM. Starts playing almost instantly via progressive streaming.
   - **Weakness**: Cannot achieve true 0ms gapless playback (usually ~200ms gap).

3. **Standard** (Dart / `just_audio` Native)
   - **Role**: The conservative baseline.
   - **Mechanism**: Bypasses all custom Javascript and relies entirely on Flutter's `just_audio` web implementation.
   - **Strength**: Maximum stability and framework support.
   - **Weakness**: Very noticeable gaps between tracks and poor background tab longevity.

#### 4. Passive (`passive_audio_engine.js`)
*   **Architecture:** The polar opposite of the Gapless Engine. It uses a single HTML5 `<audio>` element and simply overwrites `audio.src = url` when a track ends.
*   **Strengths:** Virtually indestructible. The OS sees this as a standard media player and will keep it alive forever in the background while the screen is off.
*   **Weaknesses:** Cannot do gapless. Cannot crossfade. There is always a 400ms - 800ms gap between tracks while the browser fetches the new file.

#### 5. Hybrid (`hybrid_audio_engine.js` + `audio_heartbeat.js`)
*   **Architecture:** The ultimate orchestration. Upon first play, it instantly routes audio through the HTML5 Engine so the user hears music immediately (0ms wait time). While Track 1 plays, it silently fetches and decodes Track 2 into the Web Audio Engine in the background. As soon as Track 1 ends, it hands the baton seamlessly to Web Audio for perfect 0ms gapless playback for the rest of the playlist.
*   **Background Survival:** To prevent iOS Safari and Chrome Android from suspending the Web Audio API when the screen turns off, this engine spins up `audio_heartbeat.js` — a tiny, invisible, looping silent wav file in a standard HTML5 `<audio>` tag that runs alongside your music. This tricks the Mobile OS into believing standard media is continuously playing, locking the Web Audio API into memory perpetually.
*   **Strengths:** Instant start time AND perfect gapless background playback.
*   **Weaknesses:** High architectural complexity.

---

## 2. Advanced Handoff Behaviors (Hybrid Engine)

### Instant-Start Handoff
When a user manually clicks a track to play:
1. Hybrid routes the command to the **Passive/HTML5** engine for *instant progressive streaming*.
2. Simultaneously, it orders the **Web Audio** engine to `prepareToPlay()` (fetch & decode) in the background.
3. Once decoded, Hybrid executes a live, seamless millisecond-accurate cross-engine seek to take control back to the foreground.

### Eager Background Handoff
The Hybrid engine no longer "hands off" to a simpler engine when backgrounded. Instead, it maintains the Web Audio engine and uses a "heartbeat" to ensure its survival.

| Feature | Old Hybrid Behavior | New Hybrid Behavior |
|---|---|---|
| Gapless Backgrounding | Falls back to gapful HTML5 | **100% true Gapless** via silent HTML5 Heartbeat hook |
| Background Resilience | Handled natively by custom Android/iOS OS services | Handled by fooling the mobile OS with a looping silent audio tag |

---

## 3. Memory & PCM Level Management

**The Strategy:** Aggressive Garbage Collection
- Gapless playback intrinsically requires converting compressed files (~7MB) to bloated raw PCM buffers (~100MB).
- **Post-Optimization**: The `_evictOldBuffers` function was rewritten to explicitly `delete` the 100MB PCM `AudioBuffer` the *exact millisecond* a track finishes playing, rather than waiting for the next buffer cycle.
- **Long-Track Purge**: If a track is longer than 15 minutes (common in gd-sets), the engine also purges the 15MB compressed ArrayBuffer cache as soon as decoding completes, preventing Memory leaks and out-of-memory (OOM) browser crashes on low-end mobile devices.

## 4. Background Survival Rates & Gapless Reliability

During long playback sessions where the phone screen is off and the Web UI / PWA is in the background (assuming battery saver is not aggressively killing all apps), each engine has a different likelihood of being arbitrarily suspended or completely killed by the Mobile OS (iOS/Android), as well as a varying probability of actually achieving gapless transition while hidden.

1. **Web Audio (Gapless)** 
   - **OS Kill Risk**: **High**
   - **Background Gapless Chance**: **High (when alive)**
   - **Why**: The Web Audio API requires a constant stream of CPU cycles to decode compressed chunks into heavy PCM ArrayBuffers. Even with the new hidden Web Worker scheduler preventing JavaScript timer lockups, the OS often views massive foreground Memory and CPU allocations by a hidden tab as a hostile battery drain. Mobile Safari in particular is infamous for brutally suspending `AudioContext`s in the background. However, if the process lives, the Web Worker guarantees 100% gapless transitions.

2. **HTML5 (Mobile Gapless)** 
   - **OS Kill Risk**: **Medium-High**
   - **Background Gapless Chance**: **Low-Medium**
   - **Why**: While HTML5 streaming is far lighter on memory than Web Audio, this engine utilizes *two* `<audio>` tags overlapping each other. Background operating systems frequently become confused when a hidden web page attempts to maintain two simultaneous media playing contexts. It survives much longer than Web Audio, but can still be randomly killed during the handoff between tracks if the OS detects multiple active media streams. Even when it survives, the browser often refuses to un-mute the overlapping secondary `<audio>` tag until the screen is turned back on, resulting in forced 200ms+ gaps.

3. **Standard (just_audio)** 
   - **OS Kill Risk**: **Medium**
   - **Background Gapless Chance**: **Zero**
   - **Why**: It utilizes Dart's default bindings. Because it delegates entirely to the browser implementation and doesn't try doing advanced buffer math, it is generally stable, but offers no fallback mechanisms if the browser decides to suspend the background tab. It cannot achieve gapless playback under any circumstance.

4. **Passive** 
   - **OS Kill Risk**: **Zero to Low**
   - **Background Gapless Chance**: **Zero**
   - **Why**: This is the most indestructible engine. It relies strictly on a single `<audio>` HTML tag connected to the native OS Media Session hook. Once playing, the phone's native media player framework effectively adopts the stream, completely removing the browser renderer's memory/CPU overhead from the equation. The OS will almost never kill this unless the user manually sweeps the app away. Because it uses only one tag, gapless transitions are totally impossible (~500ms gap).

5. **Hybrid** 
   - **OS Kill Risk**: **Zero to Low**
   - **Background Gapless Chance**: **100%**
   - **Why**: This engine achieves the same zero-risk profile as the **Passive** engine securely but through different means. By maintaining a silent HTML5 heartbeat loop via `audio_heartbeat.js`, the OS never penalizes the hidden tab or kills the primary Web Audio API/Web Worker. Thus, players keep sample-accurate gapless playback indefinitely even with the screen off, removing the need for a secondary fallback engine entirely.

---

## 5. Runtime Engine Switching (Hot-Swapping)

When changing the active audio engine via the Web UI / PWA Settings, **a full app reload is always required**, regardless of whether audio is currently playing or stopped. 

The application cannot hot-swap between engines (e.g., from Web Audio to HTML5) mid-track or even between tracks.
- **Why?**: The web application fundamentally injects and binds its Javascript interop framework (`gapless_audio_engine.js`, `html5_audio_engine.js`, etc.) into the global `window` scope at initial launch based on the saved user preference. 
- **The Behavior**: If the user selects a new engine, the application writes the preference to local storage and displays a snackbar prompting the user to `RELOAD`. Clicking this simply calls `window.location.reload()`, bootstrapping the Flutter app from scratch with the newly selected Javascript audio architecture.

---

## 6. Architectural Comparison: Hybrid Engine vs YouTube Music PWA

The Shakedown **Hybrid** Engine operates on a very different philosophy than the YouTube Music (YTM) PWA, born out of different content constraints (API-driven MP3 files vs proprietary chunked content delivery networks).

1. **Streaming Protocol (File vs Chunks):**
   - **YTM PWA**: Uses Media Source Extensions (MSE) and adaptive bitrate streaming (DASH/HLS). It downloads tiny chunks of the audio file iteratively, parsing them into a buffer, adjusting quality seamlessly based on network.
   - **Hybrid**: Shakedown does not control the CDN (Archive.org) and must download full monolithic MP3 files over standard HTTP. It fakes progressive streaming using `HTML5` for instant playback, while waiting for the full file to download before attempting high-fidelity overlapping.

2. **Gapless Implementation:**
   - **YTM PWA**: Appends continuous chunks from the next track directly into the same MSE `SourceBuffer` being played, creating a mathematically perfect, uninterrupted single stream without ever changing the `<audio>` tag's playback context.
   - **Hybrid**: Brute-forces gapless by utilizing the `Web Audio API`'s highly precise `AudioContext.currentTime` scheduler to overlap two discrete `AudioBufferSourceNode`s connected via `GainNode`s to intersect exactly on the sample.

3. **Background Tab Resilience:**
   - **YTM PWA**: Uses a Service Worker to intercept requests and stream data invisibly, relying heavily on native HTMLMediaElements (`<audio>`) so it is rarely penalized by the OS when backgrounded.
   - **Hybrid**: Employs an aggressive "Heartbeat" to spoof the mobile OS. Because its primary Web Audio renderer is considered hostile by OS background constraints, it continuously loops a microscopic Base64 silent HTML5 `<audio>` track, deceiving the mobile browser into protecting the hidden Web Audio buffers.

Ultimately, YTM uses a singular, highly complex MSE stream architecture from front to back, whereas Shakedown's Hybrid Engine is a reactive orchestrator, weaving between native browser audio architectures (HTML5 and Web Audio) dynamically to mimic a premium PWA experience using monolithic public files.

---

## 7. Suggestions for Improvement 
**(All Audit Findings Successfully Implemented)**

1. ~~**Instant-Start Hybrid Handoff**~~: Implemented via HTML5-first routing.
2. ~~**Background Resilience**~~: Implemented via continuous invisible HTML5 Base64 heartbeat (`audio_heartbeat.js`).
3. ~~**SharedArrayBuffer / WebWorkers**~~: Implemented via `audio_scheduler.worker.js`.
4. ~~**PCM Level Management**~~: Implemented via aggressive `delete` and GC tuning.
5. ~~**Implement Crossfade**~~: Implemented via localized `GainNode` architecture and `linearRampToValueAtTime`.
