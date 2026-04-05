# TV Beat Detection — Jules Merge Review Todos

Date: 2026-04-05
Source: Jules branch `jules-checkup-linux-fix-9749356344685601503` (commits `b87e230`, `a1f70b4`)
Files reviewed: `VisualizerPlugin.kt`, `StereoCapture.kt`

---

## VisualizerPlugin.kt

| # | Priority | Issue |
|---|---|---|
| 1 | High | **Gate autocorr BPM override with confidence comparison** — `"beatBpm" to autocorrBpm ?: trackedBeatBpm` unconditionally replaces the existing beat tracker output whenever autocorrelation fires. Only override `trackedBeatBpm` if autocorr confidence exceeds the existing beat source confidence score. Same for `beatIbiMs`. |
| 2 | High | **Remove or disable 20Hz fallback autocorr path** — Fallback RMS at 20Hz (50ms/sample) gives ±30 BPM resolution at 120 BPM — too coarse to be useful. Remove the `fallbackRmsHistory` buffer and related fields, or gate so it never overrides a live beat source. Require stereo PCM (100Hz) for autocorr to run. |
| 3 | Medium | **Guard O(n²) autocorr inner loop** — Loop is `O(count × lagRange)`, up to ~512 × lag range iterations per frame. Add a comment documenting worst-case cost and coerce `count` to a safe max (e.g. 256) to prevent unbounded growth if history sizes change. |
| 4 | Medium | **Implement second-pass autocorr refinement behind settings toggle** — Jules left a draft comment: *"You could do a second pass around bestLag at higher sample rate if you needed more precision."* Implement as a real feature: add a `beat_autocorr_second_pass` pref in `SettingsProvider` (default off), gated behind a hardware capability check — disabled by default on Sabrina (Chromecast with Google TV) which may not have headroom for the extra per-frame work. Remove the draft comment once implemented. |

---

## StereoCapture.kt

| # | Priority | Issue |
|---|---|---|
| 5 | High | **Add memory barrier for `fullRmsHistory` cross-thread access** — `@Volatile` on `rmsHistoryIndex` only covers the index reference, not array element visibility between capture thread (writer) and VisualizerPlugin (reader). Fix with a `synchronized` block or `AtomicInteger` for the index to ensure happens-before ordering. |
| 6 | Medium | **Make `fullRmsHistory` private with a read accessor** — Currently a public mutable `FloatArray` — any caller can corrupt it. Make private and expose a read-only accessor or snapshot copy method. |
| 7 | Medium | **Handle 48kHz sample rate in `RMS_BLOCK_SIZE`** — Hardcoded `441` assumes 44100Hz. Modern Android often uses 48000Hz, giving ~91Hz RMS rate instead of 100Hz. Query actual `AudioRecord` sample rate at init and compute `RMS_BLOCK_SIZE` dynamically (`sampleRate / 100`). Add a comment explaining the derivation. |
| 8 | Low | **Fix `rmsHistorySize` naming convention** — Should be `RMS_HISTORY_SIZE` in a `companion object` to match Kotlin constant conventions (consistent with `RMS_BLOCK_SIZE` already defined there). |
