# Network Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden all JS fetch calls with timeouts, status checks, and AbortController support; lock down cleartext traffic in release builds.

**Architecture:** Each JS engine's fetch calls get AbortController-based timeouts. The gapless engine already has controllers — we add a timeout arm. The html5 engine needs controllers added from scratch. Android release manifest gets `usesCleartextTraffic="false"`.

**Tech Stack:** Vanilla JS (Web Audio API engines), Android XML manifests

---

## File Map

| File | Change | Responsibility |
|------|--------|----------------|
| `apps/gdar_web/web/html5_audio_engine.js` | Modify L116-167 | Add AbortController + timeout to HEAD and GET fetches; add `response.ok` check |
| `apps/gdar_web/web/gapless_audio_engine.js` | Modify L206-215 | Add timeout arm to existing AbortController |
| `apps/gdar_mobile/android/app/src/main/AndroidManifest.xml` | Modify L33 | Remove `usesCleartextTraffic="true"` |
| `apps/gdar_mobile/android/app/src/debug/AndroidManifest.xml` | Create | Allow cleartext in debug only |

---

### Task 1: Add AbortController + timeout to html5_audio_engine.js HEAD fetch

**Files:**
- Modify: `apps/gdar_web/web/html5_audio_engine.js:116-128`

**Context:** The `loadHEAD()` method resolves track redirect URLs via a HEAD request. It has no timeout and no status check. A stalled archive.org response will hang this call forever, blocking the WebAudio decode pipeline for this track.

**Constraints from `.agent/rules/audio_engine.md`:** This is part of the HTML5 engine, not the gapless scheduler. No high-precision timing concerns here — this is a one-shot metadata check.

- [ ] **Step 1: Add AbortController with 10s timeout to loadHEAD**

Replace the `loadHEAD` method (lines 116-128) with:

```javascript
        loadHEAD(cb) {
            if (this.webAudioFetchBlocked || !this.audioContext) {
                this.loadedHEAD = true;
                cb && cb();
                return;
            }
            if (this.loadedHEAD) return cb();
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000);
            fetch(this.trackUrl, { method: 'HEAD', signal: controller.signal })
                .then((res) => {
                    clearTimeout(timeoutId);
                    if (res.ok && res.redirected) this.trackUrl = res.url;
                    this.loadedHEAD = true;
                    cb();
                })
                .catch(() => {
                    clearTimeout(timeoutId);
                    cb();
                });
        }
```

Key changes:
- AbortController with 10s timeout auto-aborts stalled HEAD requests
- `clearTimeout` in both `.then` and `.catch` prevents leaked timers
- `res.ok` check before trusting the redirect URL (non-2xx redirects are ignored)

- [ ] **Step 2: Verify in browser**

Open the PWA in Chrome DevTools. In the Network tab, confirm:
1. HEAD requests to archive.org still resolve track URLs
2. No console errors from the AbortController addition
3. Playback still transitions from HTML5 to WebAudio normally

- [ ] **Step 3: Commit**

```bash
git add apps/gdar_web/web/html5_audio_engine.js
git commit -m "fix(web): add timeout + status check to html5 engine HEAD fetch"
```

---

### Task 2: Add AbortController + timeout to html5_audio_engine.js GET fetch

**Files:**
- Modify: `apps/gdar_web/web/html5_audio_engine.js:130-167`

**Context:** The `loadBuffer()` method fetches the full audio file for WebAudio decoding. It has no timeout, no AbortController, and no `response.ok` check. A 403 or 503 response will be fed to `decodeAudioData()` as garbage, causing a silent decode failure.

- [ ] **Step 1: Add AbortController with 30s timeout and status check to loadBuffer**

Replace the `loadBuffer` method (lines 130-167) with:

```javascript
        loadBuffer(cb) {
            if (this.webAudioFetchBlocked || !this.audioContext) {
                cb && cb();
                return;
            }
            if (this.webAudioLoadingState !== GaplessPlaybackLoadingState.NONE) return;
            this.webAudioLoadingState = GaplessPlaybackLoadingState.LOADING;
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 30000);
            fetch(this.trackUrl, { signal: controller.signal })
                .then((res) => {
                    clearTimeout(timeoutId);
                    if (!res.ok) {
                        throw new Error('HTTP ' + res.status + ' fetching ' + this.trackUrl);
                    }
                    return res.arrayBuffer();
                })
                .then((res) =>
                    this.audioContext.decodeAudioData(
                        res,
                        (buffer) => {
                            this.webAudioLoadingState = GaplessPlaybackLoadingState.LOADED;
                            this.bufferSourceNode.buffer = this.audioBuffer = buffer;
                            this.bufferSourceNode.connect(this.gainNode);
                            this.queue.loadTrack(this.idx + 1);
                            if (this.isActiveTrack) this.switchToWebAudio();
                            else this.playbackType = GaplessPlaybackType.WEBAUDIO;
                            cb && cb(buffer);
                        },
                        (err) => {
                            _log.error('[html5] WA decode failed for track', this.idx, '— staying on HTML5 stream');
                            this.webAudioLoadingState = GaplessPlaybackLoadingState.NONE;
                            this.queue.onError();
                            this.webAudioFetchBlocked = true;
                            _logArchiveWebAudioSkip(this.trackUrl);
                        }
                    )
                )
                .catch((e) => {
                    clearTimeout(timeoutId);
                    _log.warn('[html5] Fetch error for track', this.idx, e && e.message);
                    this.webAudioLoadingState = GaplessPlaybackLoadingState.NONE;
                    this.queue.onError();
                    this.webAudioFetchBlocked = true;
                    _logArchiveWebAudioSkip(this.trackUrl);
                });
        }
```

Key changes:
- AbortController with 30s timeout (appropriate for full audio file download)
- `res.ok` check before calling `res.arrayBuffer()` — rejects 4xx/5xx before decode
- `clearTimeout` in both success and error paths
- Existing decode error handling and `webAudioFetchBlocked` logic preserved exactly

- [ ] **Step 2: Verify in browser**

Open the PWA. Play a track and watch the Network tab:
1. Confirm audio files still load and decode to WebAudio
2. Simulate a slow response (Chrome DevTools > Network > Throttle > Slow 3G) — verify the fetch aborts after 30s and the engine falls back to HTML5 streaming (check console for `[html5] Fetch error` message)
3. Confirm `webAudioFetchBlocked` is set on timeout so the engine doesn't retry the same broken track

- [ ] **Step 3: Commit**

```bash
git add apps/gdar_web/web/html5_audio_engine.js
git commit -m "fix(web): add timeout + status check to html5 engine buffer fetch"
```

---

### Task 3: Add timeout arm to gapless_audio_engine.js existing AbortController

**Files:**
- Modify: `apps/gdar_web/web/gapless_audio_engine.js:191-301`

**Context:** The `_fetchCompressed()` function already uses an AbortController for manual cancellation (track skip, prefetch cleanup). However, the controller is never triggered by elapsed time — if archive.org accepts the connection but stalls the response body, the fetch hangs indefinitely.

**Constraints from `.agent/rules/audio_engine.md`:**
- Protection window rule: current track and next track fetches must be protected during `_cancelPrefetch`
- Abort collision prevention: manual track selection must not kill its own fetch

These constraints are about *which* controllers get aborted, not *when*. Adding a timeout arm to each individual controller respects both rules — it only aborts its own fetch, never another track's.

- [ ] **Step 1: Add 60s timeout arm after AbortController creation**

In `_fetchCompressed()`, find this block (lines 203-214):

```javascript
    if (_abortControllers[index]) {
      try { _abortControllers[index].abort(); } catch (_) { }
    }
    const controller = new AbortController();
    _abortControllers[index] = controller;

    _log.log('[gdar engine] Fetching', index, track.url);

    _fetchStartMs = performance.now();
    _fetchInFlight = true;
    _lastFetchTtfbMs = null;
    _emitState();
    return fetch(track.url, {
```

Replace with:

```javascript
    if (_abortControllers[index]) {
      try { _abortControllers[index].abort(); } catch (_) { }
    }
    const controller = new AbortController();
    _abortControllers[index] = controller;
    const fetchTimeoutId = setTimeout(() => {
      _log.warn('[gdar engine] Fetch timeout (60s) for index', index);
      controller.abort();
    }, 60000);

    _log.log('[gdar engine] Fetching', index, track.url);

    _fetchStartMs = performance.now();
    _fetchInFlight = true;
    _lastFetchTtfbMs = null;
    _emitState();
    return fetch(track.url, {
```

- [ ] **Step 2: Clear the timeout in the success path**

Find the line after the chunked read completes (line 285):

```javascript
        delete _abortControllers[index];
```

Replace with:

```javascript
        clearTimeout(fetchTimeoutId);
        delete _abortControllers[index];
```

- [ ] **Step 3: Clear the timeout in the error path**

Find the catch block (line 290-300):

```javascript
      .catch(err => {
        _fetchInFlight = false;
        delete _abortControllers[index];
```

Replace with:

```javascript
      .catch(err => {
        clearTimeout(fetchTimeoutId);
        _fetchInFlight = false;
        delete _abortControllers[index];
```

- [ ] **Step 4: Verify in browser**

Open the PWA. Play through several tracks:
1. Confirm tracks still prefetch and play gaplessly (no regressions)
2. In Console, confirm `[gdar engine] Fetching` and `[gdar engine] Fetch complete` logs appear as normal
3. No `Fetch timeout (60s)` warnings should appear under normal conditions
4. Confirm skip-forward still works (manual abort path unchanged)

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_web/web/gapless_audio_engine.js
git commit -m "fix(web): add 60s timeout arm to gapless engine fetch controller"
```

---

### Task 4: Lock down cleartext traffic for Android release builds

**Files:**
- Modify: `apps/gdar_mobile/android/app/src/main/AndroidManifest.xml:33`
- Create: `apps/gdar_mobile/android/app/src/debug/AndroidManifest.xml`

**Context:** The main `AndroidManifest.xml` has `usesCleartextTraffic="true"` on the `<application>` tag. This allows unencrypted HTTP traffic in all build variants, including release. Archive.org uses HTTPS, so this flag is unnecessary in production. Debug builds may need it for local dev servers.

- [ ] **Step 1: Remove usesCleartextTraffic from the main manifest**

In `apps/gdar_mobile/android/app/src/main/AndroidManifest.xml`, line 33, find:

```xml
    <application android:label="@string/app_name" android:name="${applicationName}" android:roundIcon="@mipmap/ic_launcher_round" android:icon="@mipmap/ic_launcher1" android:usesCleartextTraffic="true" android:banner="@drawable/tv_banner">
```

Replace with:

```xml
    <application android:label="@string/app_name" android:name="${applicationName}" android:roundIcon="@mipmap/ic_launcher_round" android:icon="@mipmap/ic_launcher1" android:banner="@drawable/tv_banner">
```

- [ ] **Step 2: Create debug-only manifest that allows cleartext**

Create `apps/gdar_mobile/android/app/src/debug/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:usesCleartextTraffic="true" />
</manifest>
```

This is a manifest overlay — Android's build system merges it with the main manifest for debug builds only. Release builds will not have cleartext traffic allowed.

- [ ] **Step 3: Verify debug build still works**

```bash
cd apps/gdar_mobile && flutter build apk --debug 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL. The debug manifest overlay should merge cleanly.

- [ ] **Step 4: Verify release build removes cleartext**

```bash
cd apps/gdar_mobile && flutter build apk --release 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL. To double-check, inspect the merged manifest:

```bash
# After build, check the merged manifest
cat apps/gdar_mobile/build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml 2>/dev/null | grep -i cleartext
```

Expected: No `usesCleartextTraffic` attribute, or `usesCleartextTraffic="false"`.

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_mobile/android/app/src/main/AndroidManifest.xml apps/gdar_mobile/android/app/src/debug/AndroidManifest.xml
git commit -m "fix(android): restrict cleartext traffic to debug builds only"
```
