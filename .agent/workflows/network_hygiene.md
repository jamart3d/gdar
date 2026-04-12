---
description: Audit network calls across all platforms for correctness, efficiency, and protocol compliance.
---
# Network Hygiene Workflow (Monorepo)

**TRIGGERS:** network_hygiene, network_audit, http_audit, fetch_audit

Use this workflow to verify that all network calls across mobile, TV, and
web/PWA are well-behaved: not excessive, properly guarded, timeout-aware,
and following protocol best practices.

## 1. Inventory All Network Call Sites

Scan for network usage across all platforms:

### Dart (apps/ + packages/)
- Search for imports: `package:http/`, `dart:io` HttpClient, `package:dio/`
- Search for `Uri.parse`, `http.get`, `http.post`, `http.head`, `http.Client`
- Search for WebSocket usage: `WebSocket`, `WebSocketChannel`
- Search for `connectivity_plus` listeners

### JavaScript (apps/gdar_web/web/)
- Search for `fetch(`, `XMLHttpRequest`, `navigator.sendBeacon`
- Search for `AbortController` usage and cancellation patterns
- Search for `WebSocket` connections

### Platform APIs
- Search for `InAppUpdate`, `InAppReview`, or Play Store API calls
- Search for `firebase`, `analytics`, `crashlytics` imports

Record each call site with: file, line, HTTP method, URL pattern, purpose.

## 2. Timeout & Retry Audit

For each network call site, verify:

| Check | Pass Criteria |
|-------|---------------|
| **Timeout present** | Every outbound request has an explicit timeout (recommend: 5-10s for metadata, 15-30s for media) |
| **Retry policy** | Retries use backoff (not tight loops); max 3 attempts for non-idempotent calls |
| **AbortController (JS)** | Fetch calls use AbortController signals; controllers are cleaned up on dispose/unmount |
| **Cancellation (Dart)** | Long-running requests are cancellable (e.g., on screen exit or provider dispose) |

Flag any call without a timeout as **HIGH** severity.

## 3. Excessive Call Detection

Check for patterns that indicate wasteful network usage:

- **Polling without backoff:** Repeated calls on a fixed timer without exponential backoff
- **Duplicate requests:** Same URL fetched multiple times in quick succession (< 2s)
- **Missing dedup:** Identical requests fired from multiple providers/widgets simultaneously
- **Unnecessary prefetch depth:** Pre-loading more tracks than needed for smooth playback
- **Reachability spam:** Connectivity checks firing more often than every 30s
- **Cold-start burst:** Multiple network calls all firing at app init without staggering

## 4. Protocol & Header Compliance

| Check | Pass Criteria |
|-------|---------------|
| **User-Agent** | All requests set a descriptive User-Agent (e.g., `GDAR/x.y.z (contact@email)`) |
| **HTTPS** | No cleartext HTTP in production (debug-only exceptions must be gated) |
| **CORS awareness** | Web-platform code skips or handles CORS-restricted endpoints gracefully |
| **Cache headers** | Responses that can be cached (metadata, album art) use appropriate caching |
| **Content-Type** | POST/PUT requests set correct Content-Type headers |
| **Status code handling** | Non-2xx responses are checked and handled (not silently ignored) |

## 5. Error Handling & Recovery

For each call site verify:

- **Graceful degradation:** Network failure doesn't crash the app or leave broken UI state
- **User feedback:** Long-running failures surface a message (not silent black holes)
- **Offline resilience:** App remains functional when network is unavailable
- **Error logging:** Failures are logged with enough context to diagnose (URL, status, error type)
- **No leaked exceptions:** All network calls are wrapped in try/catch or .catchError

## 6. Platform-Specific Checks

### Mobile / TV (Dart)
- Verify `http.Client` instances are closed/disposed properly
- Check that background network calls respect app lifecycle (pause/resume)
- Verify AndroidManifest `usesCleartextTraffic` is false in release builds

### Web / PWA
- Verify fetch calls handle ServiceWorker cache interactions correctly
- Check that AbortController maps don't leak (entries removed after completion)
- Verify no synchronous XHR calls (blocks main thread)
- Check that audio prefetch respects `document.hidden` (background tab throttling)

## 7. Save Report

Ensure `reports/` exists.
Save results to: `reports/NETWORK_HYGIENE_REPORT_YYYY-MM-DD.md`

Use this template:
```md
# Network Hygiene Report
Date: YYYY-MM-DD

## Scope
- apps/ (mobile, tv, web)
- packages/

## Network Call Inventory
| File | Line | Method | URL Pattern | Timeout | Retry | Purpose |
|------|------|--------|-------------|---------|-------|---------|

## Findings

### HIGH — Missing Timeouts / Unguarded Calls
- [file:line] description

### MEDIUM — Protocol / Header Issues
- [file:line] description

### LOW — Optimization Opportunities
- [file:line] description

## Excessive Call Risk
- finding

## Platform-Specific Issues
- finding

## Notes / False Positives
- note
```

## 8. Guardrails
- Do not modify any network code from this workflow.
- Treat findings as candidates until verified in context.
- Archive.org cleartext HTTP in debug manifests is expected — flag but don't mark as critical.
- `just_audio` and `connectivity_plus` internal network calls are out of scope (library-managed).
- If deeper analysis requires running the app or inspecting DevTools traffic, call that out and wait for user approval.
