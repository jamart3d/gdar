# Web Gapless Playback — Technical Implementation Plan
**Date:** 2026-02-23  
**Project:** GDAR (Shakedown)  
**Goal:** Zero-millisecond latency between tracks on Chrome & Safari (desktop + mobile)

---

## Executive Summary

Your Android app achieves true gapless playback via ExoPlayer's native playlist stitching. The web platform has **no equivalent native primitive**. This plan documents what is achievable, what is not, and a tiered strategy to get as close to zero-gap as the browser allows.

> [!CAUTION]
> **`just_audio_web` uses HTML5 `<audio>` elements under the hood — NOT the Web Audio API.** This means sample-accurate stitching is not available through the `just_audio` package alone on the web. The gap between tracks is typically 20–80 ms depending on browser, codec, and network latency. This plan proposes strategies to minimize that gap, and a path toward eliminating it entirely.

---

## 1. Web Audio Engine Configuration

### 1.1 Current State: `just_audio_web` Internals

| Aspect | Android (ExoPlayer) | Web (`just_audio_web`) |
|---|---|---|
| Backend | `MediaCodec` / ExoPlayer | HTML5 `<audio>` element |
| Gapless mechanism | Native playlist stitching | Sequential `<audio>` element swap |
| Timing precision | Sample-accurate (~0 ms) | Event-loop dependent (~20–80 ms) |
| Pre-decode next track | ✅ ExoPlayer handles | ❌ No pre-decode |

### 1.2 Tier 1 — Pragmatic (just_audio defaults)

Use `just_audio` as-is on web. Accept a ~30–80 ms gap. This is the **lowest-effort** path.

```dart
// Your existing code in audio_provider.dart already works on web:
await _audioPlayer.setAudioSources(
  children,
  initialIndex: initialIndex,
  initialPosition: initialPosition,
  preload: true,  // ← change from dynamic offlineBuffering to always-true on web
);
```

**Expected result:** Audible micro-gap between tracks. Acceptable for casual listening, not for live Grateful Dead recordings where songs segue.

### 1.3 Tier 2 — Optimized (preload + warm handoff)

Reduce the gap to ~10–30 ms by eagerly preloading the next track's `<audio>` element.

```dart
// Pseudocode — web-specific optimization layer
import 'dart:html' as html;

class WebPreloader {
  html.AudioElement? _nextAudio;

  /// Call ~10 seconds before current track ends.
  void preloadNext(String url) {
    _nextAudio?.remove();
    _nextAudio = html.AudioElement(url)
      ..preload = 'auto'    // browser pre-fetches and decodes
      ..load();             // force fetch start
  }

  /// When current track ends, the preloaded element is ready instantly.
  html.AudioElement? consumePreloaded() {
    final el = _nextAudio;
    _nextAudio = null;
    return el;
  }
}
```

> [!NOTE]
> This requires a **platform-specific Dart file** (`audio_preloader_web.dart`) guarded by `kIsWeb`, since `dart:html` is web-only. Your existing `audio_provider.dart` would call this conditionally.

### 1.4 Tier 3 — Ambitious (Custom Web Audio API Engine)

Replace `just_audio_web` with a custom implementation that uses `AudioBufferSourceNode` scheduling for **true sample-accurate transitions**.

```
┌─────────────────────────────────────────────────────┐
│                  AudioContext                        │
│                                                      │
│  Track N (playing)         Track N+1 (scheduled)     │
│  ┌──────────────┐          ┌──────────────┐          │
│  │ AudioBuffer  │──GainNode│ AudioBuffer  │──GainNode│
│  │ SourceNode   │    │     │ SourceNode   │    │     │
│  └──────────────┘    │     └──────────────┘    │     │
│                      ▼                          ▼     │
│               ┌──────────────────────┐               │
│               │    Destination       │               │
│               └──────────────────────┘               │
└─────────────────────────────────────────────────────┘
```

**How it works:**
1. Fetch track N+1 via `fetch()` → `ArrayBuffer`
2. Decode with `AudioContext.decodeAudioData()` → `AudioBuffer`
3. Create `AudioBufferSourceNode`, schedule `start(trackN_endTime)` using `AudioContext.currentTime`
4. The Web Audio API scheduler stitches at the sample level — **zero gap**

**Trade-offs:**
- Entire tracks must be decoded into memory (~10 MB per 5-minute MP3 at 128kbps decoded to PCM)
- No streaming — must download complete file before playback
- Requires forking or bypassing `just_audio_web`
- Safari's Web Audio API has known quirks with `decodeAudioData` for long files

---

## 2. Buffer Strategy

### 2.1 For Tier 1/2 (just_audio playlist)

```dart
// In _loadAndPlayAudio, web-specific settings:
await _audioPlayer.setAudioSources(
  children,
  initialIndex: initialIndex,
  initialPosition: initialPosition,
  preload: true,  // Always preload on web — no ExoPlayer memory concerns
);
```

| Setting | Value | Rationale |
|---|---|---|
| `preload` | `true` | Pre-fetches next track metadata + initial bytes |
| Source type | `AudioSource.uri()` | Standard HTTP fetch, browser manages cache |

### 2.2 For Tier 3 (Web Audio API)

| Concern | Strategy |
|---|---|
| Memory budget | Decode at most **2 tracks** at a time (current + next). ~20 MB peak for 128kbps MP3 |
| Prefetch trigger | Start fetching N+1 when N has **30 seconds remaining** |
| Eviction | Release `AudioBuffer` for N-1 immediately after transition |
| Long shows (30+ tracks) | Lazy pipeline — never more than 2 decoded buffers in RAM |

```dart
// Pseudocode for web audio buffer manager
class WebAudioBufferManager {
  static const _prefetchThresholdSeconds = 30;
  static const _maxDecodedBuffers = 2;
  
  final Map<int, AudioBuffer> _decodedBuffers = {};
  
  Future<void> prefetchIfNeeded(int currentIndex, double remainingSeconds) async {
    if (remainingSeconds <= _prefetchThresholdSeconds) {
      final nextIndex = currentIndex + 1;
      if (!_decodedBuffers.containsKey(nextIndex)) {
        final buffer = await _fetchAndDecode(nextIndex);
        _decodedBuffers[nextIndex] = buffer;
        _evictOld(currentIndex);
      }
    }
  }
  
  void _evictOld(int currentIndex) {
    _decodedBuffers.removeWhere((key, _) => key < currentIndex);
  }
}
```

---

## 3. Infrastructure Requirements

### 3.1 Mandatory HTTP Headers from archive.org

GDAR streams from `https://archive.org/download/{identifier}/{filename}.mp3`. This is a **cross-origin** request relative to your web app's domain.

| Header | Required Value | Purpose |
|---|---|---|
| `Access-Control-Allow-Origin` | `*` or your domain | Allows cross-origin `fetch()` |
| `Access-Control-Allow-Headers` | `Range` | Allows Range header in preflight |
| `Access-Control-Expose-Headers` | `Content-Length, Content-Range, Accept-Ranges` | Lets JS read response metadata |
| `Accept-Ranges` | `bytes` | Enables seeking |
| `Content-Type` | `audio/mpeg` | Correct MIME for MP3 decoding |
| `Content-Length` | `<file size>` | Required for progress/duration |

> [!IMPORTANT]
> **archive.org already provides these headers** for their download endpoints. However, you should verify by running:
> ```bash
> curl -I "https://archive.org/download/gd1977-05-08.111324.sbd.miller.flac2496/gd77-05-08d1t01.mp3"
> ```
> Confirm `Access-Control-Allow-Origin: *` is present. If not, you'll need a **CORS proxy** for the web build.

### 3.2 CORS Proxy Fallback

If archive.org blocks CORS for your domain:

```dart
// web-only URL transform
String webAudioUrl(String archiveUrl) {
  if (kIsWeb && !_corsVerified) {
    return 'https://your-proxy.example.com/audio?url=${Uri.encodeComponent(archiveUrl)}';
  }
  return archiveUrl;
}
```

A lightweight proxy (Cloudflare Worker, Vercel Edge Function) adds `Access-Control-Allow-Origin: *` to the archive.org response. Cost: near-zero for streaming (no data stored).

### 3.3 AudioContext Lifetime

The browser will **garbage-collect** an `AudioContext` if:
- No audio nodes are connected
- The tab is backgrounded and silent for extended periods (Safari is aggressive)

**Mitigation:** Keep the `AudioContext` alive by connecting a silent `GainNode` with `gain.value = 0` to `destination` at all times.

---

## 4. State Management: User Gesture & Background Tabs

### 4.1 User Gesture Requirements

| Browser | Policy |
|---|---|
| Chrome | `AudioContext` starts `suspended`. Must call `resume()` from a user click/tap handler. Tabs with high Media Engagement Index (MEI) are exempt. |
| Safari | Strictly requires user gesture. No MEI exemption. `AudioContext` may re-suspend after long inactivity. |

**Implementation:**

```dart
// In your web entry point or first user interaction handler:
import 'dart:html' as html;
import 'dart:js' as js;

void unlockAudioContext() {
  final ctx = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
  if (ctx != null) {
    // Attempt resume on first user interaction
    html.document.body?.addEventListener('click', (_) {
      js.context.callMethod('eval', [
        'if (window._gdarAudioCtx && window._gdarAudioCtx.state === "suspended") '
        '{ window._gdarAudioCtx.resume(); }'
      ]);
    }, true);  // capture phase — fires before any other handler
  }
}
```

> [!TIP]
> `just_audio` already handles `AudioContext` resume internally for basic playback. The above is only needed if you implement Tier 3 (custom Web Audio API engine). For Tier 1/2, just_audio's built-in gesture handling is sufficient.

### 4.2 Background Tab Throttling

| Scenario | Chrome | Safari |
|---|---|---|
| Tab playing audible audio | **Exempt** from throttling | **Mostly exempt**, but may suspend AudioContext after extended inactivity |
| Tab playing silent audio | Throttled (timers → 1/min after 5 min) | Aggressively throttled |
| Tab with no audio | Fully throttled | Fully throttled |

**Mitigations:**

1. **Keep audio audible**: Never pause between tracks. Schedule the next `AudioBufferSourceNode` before the current one ends — the audio pipeline never goes silent, so Chrome never throttles.

2. **Safari keepalive**: Periodically call `audioContext.resume()` from a `setInterval` (runs at reduced frequency in background, but still executes):
   ```dart
   // Web-only keepalive
   Timer.periodic(Duration(seconds: 10), (_) {
     if (kIsWeb) {
       // Prevent Safari from suspending the AudioContext
       js.context.callMethod('eval', [
         'if (window._gdarAudioCtx) window._gdarAudioCtx.resume();'
       ]);
     }
   });
   ```

3. **Avoid `setTimeout` for scheduling**: Use `AudioContext.currentTime` for all timing. JavaScript timers are unreliable in background tabs; the Web Audio clock runs independently of the main thread.

---

## 5. Recommendation

| Tier | Gap | Effort | Recommended? |
|---|---|---|---|
| **Tier 1** — just_audio defaults | ~30–80 ms | None | ✅ Ship this first |
| **Tier 2** — Preload warm handoff | ~10–30 ms | Medium (platform-specific code) | ✅ Good ROI |
| **Tier 3** — Custom Web Audio API | ~0 ms | Very High (fork/replace just_audio_web) | ⚠️ Only if web is primary target |

> [!IMPORTANT]
> **My recommendation is to start with Tier 1**, verify it works acceptably for your use case, and then iterate to Tier 2 if the gaps are noticeable. Tier 3 is a significant engineering effort that is only justified if GDAR's web experience is a primary product goal.

---

## Verification Plan

### Automated Tests
- Measure inter-track gap using Web Audio API's `currentTime` before/after track transition
- Cross-browser testing: Chrome, Safari, Firefox (desktop + mobile)

### Manual Verification
- Play a seamless show (e.g., `gd1977-05-08` — the famous Cornell show) and listen for gaps at track boundaries
- Test background tab behavior: start playback, switch tabs, verify no stall after 5+ minutes
- Test on Safari iOS: verify `AudioContext` resume after lock/unlock cycle
