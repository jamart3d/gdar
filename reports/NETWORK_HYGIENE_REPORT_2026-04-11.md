# Network Hygiene Report
Date: 2026-04-11

## Scope
- apps/ (mobile, tv, web)
- packages/

## Network Call Inventory

### Dart (Mobile / TV / Shared)

| File | Line | Method | URL Pattern | Timeout | Retry | Purpose |
|------|------|--------|-------------|---------|-------|---------|
| `shakedown_core/lib/providers/show_list_provider.dart` | 359-366 | HEAD | `https://archive.org` | 5s | 3x / 2s backoff | Archive reachability check |
| `shakedown_core/lib/services/audio_cache_service_io.dart` | 286-293 | GET | `archive.org/download/...` | 10s | loop-based | Audio track preload to cache |
| `shakedown_core/lib/ui/screens/onboarding_screen.dart` | 69-76 | HEAD | `https://archive.org` | 3s | none | Archive reachability indicator |
| `shakedown_core/lib/services/update_service.dart` | 19 | Platform | Play Store API | platform | none | In-app update check |
| `shakedown_core/lib/services/update_service.dart` | 65 | Platform | Play Store API | platform | none | Flexible update download |
| `shakedown_core/lib/services/buffer_agent.dart` | 55-57 | Event | connectivity_plus | event-driven | N/A | Connectivity monitoring |

### JavaScript (Web / PWA)

| File | Line | Method | URL Pattern | AbortController | Status Check | Purpose |
|------|------|--------|-------------|-----------------|--------------|---------|
| `html5_audio_engine.js` | 123 | HEAD | track URL | none | none | Track redirect resolution |
| `html5_audio_engine.js` | 137 | GET | track URL | none | none | WebAudio buffer decode |
| `gapless_audio_engine.js` | 214 | GET | track URL | yes (signal + cleanup) | yes (`!r.ok`) | Primary audio streaming |

## Findings

### HIGH — Missing Timeouts / Unguarded Calls

1. **`html5_audio_engine.js:123` — HEAD fetch has no timeout or AbortController**
   - Can hang indefinitely if archive.org is slow/unresponsive
   - No `response.ok` check — redirected URLs accepted blindly
   - Has `.catch()` error handling (good), but no timeout boundary
   - **Fix:** Add AbortController with 10s timeout

2. **`html5_audio_engine.js:137` — GET fetch has no timeout or AbortController**
   - Downloads full audio buffer with no cancellation mechanism
   - No `response.ok` check before calling `res.arrayBuffer()`
   - A non-2xx response (403, 503) will produce a corrupt buffer silently
   - **Fix:** Add AbortController with 30s timeout; check `response.ok` before decode

3. **`gapless_audio_engine.js:214` — AbortController present but no timeout trigger**
   - Controller exists and is used for cancellation, but is never auto-triggered by elapsed time
   - Fetch could hang if server accepts connection but stalls the response body
   - **Fix:** Add `setTimeout(() => controller.abort(), 60000)` with cleanup on success

### MEDIUM — Protocol / Header Issues

4. **`AndroidManifest.xml:33` — `usesCleartextTraffic="true"` in main manifest**
   - Allows HTTP (non-HTTPS) traffic in all build variants including release
   - No `src/release/AndroidManifest.xml` exists to override this
   - Archive.org uses HTTPS, so this is likely a leftover from early development
   - **Fix:** Add `apps/gdar_mobile/android/app/src/release/AndroidManifest.xml` with `usesCleartextTraffic="false"`, or add a network security config that only allows cleartext for debug

5. **`html5_audio_engine.js:123,137` — No User-Agent header on fetch calls**
   - Dart calls properly set `User-Agent: GDAR/1.0.0 (shakedown_app@googlegroups.com)`
   - JS fetch calls send browser default User-Agent only
   - Browser `fetch()` restricts User-Agent modification (forbidden header), so this is **expected behavior** — not fixable

6. **`audio_cache_service_io.dart:297` — Status check only accepts `== 200`**
   - Doesn't handle 206 (Partial Content) if server sends range responses
   - Archive.org typically returns 200 for full downloads, so practical risk is low
   - **Fix (optional):** Widen to `>= 200 && < 300`

### LOW — Optimization Opportunities

7. **`onboarding_screen.dart:69` — No retry on archive reachability check**
   - `show_list_provider.dart` retries 3x with 2s backoff for the same check
   - Onboarding fires once at screen init; a transient failure shows "unreachable" permanently
   - Practical risk low since onboarding is rarely shown
   - **Fix (optional):** Add single retry with 2s delay

## Excessive Call Risk

- **No polling patterns found.** Connectivity monitoring is event-driven via `connectivity_plus`. Buffer agent checks buffering state every 5s (local timer, not network).
- **No cold-start burst.** Archive check and update check fire independently; no concurrent flood.
- **Prefetch is well-governed.** Gapless engine limits prefetch depth (30s foreground / 90s background), respects `document.visibilityState`, and uses a `_failedTracks` sentinel to avoid re-fetch loops.
- **No duplicate requests.** Preload checks cache before fetching; gapless engine deduplicates decode promises.

## Platform-Specific Issues

### Android
- **`usesCleartextTraffic="true"`** — see MEDIUM #4 above
- **http.Client disposal** — properly closed in `AudioCacheService.dispose()` (line 63) ✅
- **InAppUpdate** — delegates to Play Store library; no explicit timeout but platform-managed ✅

### Web / PWA
- **No ServiceWorker** registered — no cache API complexity, but also no offline support for static assets
- **No synchronous XHR** anywhere ✅
- **AbortController cleanup** in gapless engine is thorough (deletes from map in `.finally`) ✅
- **html5_audio_engine.js** is the weakest link — both fetches unguarded

### TV
- TV shares the mobile Dart networking stack (same `audio_cache_service_io.dart`, same `show_list_provider.dart`). No TV-specific network calls.

## Summary Scorecard

| Category | Score | Notes |
|----------|-------|-------|
| **Timeouts** | 7/10 | Dart: excellent. JS gapless: has abort but no timeout trigger. JS html5: no timeout at all. |
| **Error Handling** | 9/10 | Comprehensive across all platforms. Every call has try/catch or .catch(). |
| **Status Checks** | 7/10 | Dart: thorough. Gapless JS: checks `r.ok`. HTML5 JS: missing entirely. |
| **Client Lifecycle** | 9/10 | http.Client properly disposed. AbortControllers cleaned up in gapless. |
| **Excessive Calls** | 10/10 | No polling, no bursts, prefetch well-governed. |
| **Protocol Compliance** | 8/10 | User-Agent on Dart calls, HTTPS everywhere. Cleartext flag is the gap. |
| **Overall** | **8.3/10** | Solid foundation. Three JS fetch calls and one manifest flag are the gaps. |

## Notes / False Positives

- **User-Agent on JS fetch (#5):** Browser `fetch()` forbids setting User-Agent — this is a platform limitation, not a code issue.
- **InAppUpdate timeout:** Platform-managed; adding a Dart-level wrapper timeout is possible but adds complexity for minimal gain.
- **`audio_cache_service_io.dart` 200-only check (#6):** Archive.org returns 200 for full file downloads. Partial Content (206) would only apply if Range headers were sent, which they aren't. Cosmetic fix.
- **No ServiceWorker:** Deliberate choice — avoids cache staleness bugs. Not a finding.
