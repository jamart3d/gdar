# StereoCapture RMS Hardening — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four code-quality issues in `StereoCapture.kt` (TV only): rename `rmsHistorySize` to Kotlin constant convention, add thread-safe accessor replacing public mutable array, and compute `RMS_BLOCK_SIZE` dynamically from the actual capture sample rate.

**Architecture:** All changes are in `gdar_tv` — mobile `StereoCapture.kt` has no RMS history and is not touched. Steps 5+6 (memory barrier + encapsulation) are implemented together via a dedicated RMS lock plus a thread-safe snapshot accessor. Step 7 (dynamic sample rate) requests a preferred rate from `MainActivity`, then confirms the effective capture rate from the constructed `AudioRecord` before deriving `rmsBlockSize`.

**Tech Stack:** Kotlin, Android AudioRecord/AudioManager, no new dependencies.

---

## Files Modified

| File | Change |
|---|---|
| `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt` | All 4 steps — rename constant, make fields private, add `getRmsSnapshot()`, dynamic rmsBlockSize |
| `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt` | Steps 5+6 reader — replace 4 direct field reads with `getRmsSnapshot()` call |
| `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MainActivity.kt` | Step 7 — query AudioManager preferred rate, pass to `stereoCapture.start()` |

---

## Task 1: Rename `rmsHistorySize` to Kotlin constant convention (Step 8)

**Files:**
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`

This is a pure rename. `rmsHistorySize = 512` is currently a public instance `val` outside the companion object. Kotlin convention for compile-time constants is `UPPER_SNAKE_CASE` in a `companion object`.

- [ ] **Step 1.1: Move `rmsHistorySize` into companion object as a const**

In `StereoCapture.kt`, the companion object is at lines 31–38. Currently it contains:
```kotlin
companion object {
    private const val TAG = "StereoCapture"
    private const val SAMPLE_RATE = 44100
    const val WAVEFORM_POINTS = 256
    private const val MAX_CONSECUTIVE_SHORT_READS = 25
    private const val MAX_PCM_IDLE_MS = 2500L
    private const val HOT_PCM_LOG_THRESHOLD = 0.01
}
```

Add `RMS_HISTORY_SIZE` there and remove the instance val at line 73:

```kotlin
companion object {
    private const val TAG = "StereoCapture"
    private const val SAMPLE_RATE = 44100
    const val WAVEFORM_POINTS = 256
    private const val MAX_CONSECUTIVE_SHORT_READS = 25
    private const val MAX_PCM_IDLE_MS = 2500L
    private const val HOT_PCM_LOG_THRESHOLD = 0.01
    const val RMS_HISTORY_SIZE = 512
}
```

Remove the old line (line 73):
```kotlin
val rmsHistorySize = 512   // DELETE THIS
```

- [ ] **Step 1.2: Update all references to `rmsHistorySize` in StereoCapture.kt**

Three occurrences — replace `rmsHistorySize` with `RMS_HISTORY_SIZE`:

Line 74 (array allocation):
```kotlin
// old:
val fullRmsHistory = FloatArray(rmsHistorySize)
// new:
val fullRmsHistory = FloatArray(RMS_HISTORY_SIZE)
```

Line 378 (index wrap in processBuffer):
```kotlin
// old:
rmsHistoryIndex = (rmsHistoryIndex + 1) % rmsHistorySize
// new:
rmsHistoryIndex = (rmsHistoryIndex + 1) % RMS_HISTORY_SIZE
```

Line 379 (count cap in processBuffer):
```kotlin
// old:
if (rmsHistoryCount < rmsHistorySize) rmsHistoryCount++
// new:
if (rmsHistoryCount < RMS_HISTORY_SIZE) rmsHistoryCount++
```

- [ ] **Step 1.3: Update the VisualizerPlugin reader reference**

In `VisualizerPlugin.kt`, line 923:
```kotlin
// old:
val size = if (useStereoRms) stereoCapture.rmsHistorySize else RMS_HISTORY_SIZE
// new:
val size = if (useStereoRms) StereoCapture.RMS_HISTORY_SIZE else RMS_HISTORY_SIZE
```

(This reference goes away entirely in Task 3, but fix it now so the build doesn't break between tasks.)

- [ ] **Step 1.4: Verify the build compiles**

```bash
cd apps/gdar_tv && ./gradlew assembleDebug 2>&1 | tail -20
```

Expected: `BUILD SUCCESSFUL`. If not, fix compilation errors before continuing.

- [ ] **Step 1.5: Commit**

```bash
git add apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt \
        apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt
git commit -m "refactor(tv): rename rmsHistorySize → RMS_HISTORY_SIZE in companion object"
```

---

## Task 2: Memory barrier + encapsulation via snapshot accessor (Steps 5+6)

**Files:**
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`

**Background:** `fullRmsHistory` is a public mutable `FloatArray` written on the capture thread and read on the visualizer thread. `@Volatile` on `rmsHistoryIndex` covers the index reference but NOT array element visibility — the JVM memory model does not guarantee that array element writes are visible to other threads just because a related volatile was written. Fix: guard writes, reads, and reset with a dedicated private lock object.

The public accessor `getRmsSnapshot()` handles both concerns simultaneously:
- It's lock-guarded → establishes happens-before
- It copies the data out → caller gets an immutable snapshot, can't corrupt the buffer

- [ ] **Step 2.1: Add `RmsSnapshot` data class**

Add this just before the `class StereoCapture {` declaration (or inside as a nested class — either is fine; inside is cleaner for scoping):

```kotlin
class StereoCapture {

    data class RmsSnapshot(
        /** RMS samples ordered oldest → newest. */
        val samples: FloatArray,
        /** Number of valid samples in [samples]. */
        val count: Int,
    )

    // ... rest of class
```

- [ ] **Step 2.2: Make `fullRmsHistory`, `rmsHistoryIndex`, `rmsHistoryCount` private**

Change the three declarations (around lines 74–76 after Task 1):

```kotlin
// old:
val fullRmsHistory = FloatArray(RMS_HISTORY_SIZE)
@Volatile var rmsHistoryIndex = 0
@Volatile var rmsHistoryCount = 0

// new:
private val fullRmsHistory = FloatArray(RMS_HISTORY_SIZE)
private var rmsHistoryIndex = 0
private var rmsHistoryCount = 0
```

Note: `@Volatile` is removed — access is now guarded by `synchronized(this)` in both read and write paths, which provides stronger ordering guarantees.

- [ ] **Step 2.3: Add an RMS lock and `getRmsSnapshot()` accessor**

Add this method after the `lastAnalysisMs` property (after the field declarations block, before the private fields):

```kotlin
private val rmsHistoryLock = Any()

/**
 * Returns a consistent snapshot of the RMS history for autocorrelation analysis,
 * or null if no data has been collected yet.
 *
 * Samples are ordered oldest → newest. This accessor is thread-safe: it
 * synchronizes on [rmsHistoryLock] to establish happens-before ordering between
 * the capture thread (writer) and VisualizerPlugin (reader).
 */
fun getRmsSnapshot(): RmsSnapshot? = synchronized(rmsHistoryLock) {
    val count = rmsHistoryCount
    if (count == 0) {
        null
    } else {
        val idxHead = rmsHistoryIndex
        val samples = FloatArray(count)
        for (i in 0 until count) {
            val idx = (idxHead - count + i + RMS_HISTORY_SIZE) % RMS_HISTORY_SIZE
            samples[i] = fullRmsHistory[idx]
        }
        RmsSnapshot(samples, count)
    }
}
```

- [ ] **Step 2.4: Guard the write path in `processBuffer` with the RMS lock**

In `processBuffer`, the block that writes to the RMS history (currently around lines 372–382 after Task 1):

```kotlin
// old:
val rms = sqrt(rmsAccum / rmsSamples).toFloat()
fullRmsHistory[rmsHistoryIndex] = rms
rmsHistoryIndex = (rmsHistoryIndex + 1) % RMS_HISTORY_SIZE
if (rmsHistoryCount < RMS_HISTORY_SIZE) rmsHistoryCount++
rmsAccum = 0.0
rmsSamples = 0

// new:
val rms = sqrt(rmsAccum / rmsSamples).toFloat()
synchronized(rmsHistoryLock) {
    fullRmsHistory[rmsHistoryIndex] = rms
    rmsHistoryIndex = (rmsHistoryIndex + 1) % RMS_HISTORY_SIZE
    if (rmsHistoryCount < RMS_HISTORY_SIZE) rmsHistoryCount++
}
rmsAccum = 0.0
rmsSamples = 0
```

`rmsAccum` and `rmsSamples` are only touched on the capture thread, so they don't need synchronization.

- [ ] **Step 2.5: Guard `resetAnalysisState()` RMS history mutations with the same lock**

The reset path also mutates the ring buffer and indices, so keep it under the same lock to avoid racing a snapshot read during shutdown:

```kotlin
synchronized(rmsHistoryLock) {
    rmsHistoryIndex = 0
    rmsHistoryCount = 0
    fullRmsHistory.fill(0f)
}
```

- [ ] **Step 2.6: Verify the build compiles**

```bash
cd apps/gdar_tv && ./gradlew assembleDebug 2>&1 | tail -20
```

Expected: `BUILD SUCCESSFUL`. The VisualizerPlugin references to the now-private fields (`fullRmsHistory`, `rmsHistoryIndex`, `rmsHistoryCount`) will be compilation errors — that's fine; fix them in Task 3.

If there are errors beyond those four field references, fix them before continuing.

- [ ] **Step 2.7: Commit**

```bash
git add apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt
git commit -m "fix(tv): add synchronized RmsSnapshot accessor; make rmsHistory fields private"
```

---

## Task 3: Update VisualizerPlugin to use `getRmsSnapshot()` (Steps 5+6 reader)

**Files:**
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`

The current reader block (around lines 918–935) reads four fields directly:
```kotlin
val useStereoRms = hasStereoPcm && stereoCapture.rmsHistoryCount >= 200
val useFallbackRms = !useStereoRms && fallbackRmsHistoryCount >= 100

if (useStereoRms || useFallbackRms) {
    val count = if (useStereoRms) stereoCapture.rmsHistoryCount else fallbackRmsHistoryCount
    val size = if (useStereoRms) StereoCapture.RMS_HISTORY_SIZE else RMS_HISTORY_SIZE
    val idxHead = if (useStereoRms) stereoCapture.rmsHistoryIndex else fallbackRmsHistoryIndex
    val srcBuffer = if (useStereoRms) stereoCapture.fullRmsHistory else fallbackRmsHistory

    // Unroll the circular RMS buffer into a flat array
    val rawRms = FloatArray(count)
    var sum = 0f
    for (i in 0 until count) {
        val idx = (idxHead - count + i + size) % size
        val v = srcBuffer[idx]
        rawRms[i] = v
        sum += v
    }
    ...
```

After Task 2, `getRmsSnapshot()` returns an already-unrolled `FloatArray`, so the circular-buffer unrolling loop can be removed for the stereo path. The fallback path (local `fallbackRmsHistory`) is not from StereoCapture and stays unchanged.

- [ ] **Step 3.1: Replace the stereo reader block**

Replace the entire block described above with:

```kotlin
val stereoSnapshot = if (hasStereoPcm) stereoCapture.getRmsSnapshot() else null
val useStereoRms = stereoSnapshot != null && stereoSnapshot.count >= 200
val useFallbackRms = !useStereoRms && fallbackRmsHistoryCount >= 100

if (useStereoRms || useFallbackRms) {
    val rawRms: FloatArray
    val count: Int

    if (useStereoRms) {
        // getRmsSnapshot() returns samples ordered oldest → newest — no unrolling needed.
        rawRms = stereoSnapshot!!.samples
        count = stereoSnapshot.count
    } else {
        // Unroll the fallback circular RMS buffer (local, single-threaded)
        count = fallbackRmsHistoryCount
        val size = RMS_HISTORY_SIZE
        val idxHead = fallbackRmsHistoryIndex
        rawRms = FloatArray(count)
        for (i in 0 until count) {
            val idx = (idxHead - count + i + size) % size
            rawRms[i] = fallbackRmsHistory[idx]
        }
    }

    var sum = 0f
    for (v in rawRms) sum += v
    ...
```

Everything after the `var sum = 0f` line (mean subtraction, lag computation, etc.) stays exactly as-is — it operates on `rawRms` and `count` which are still the same local variables.

- [ ] **Step 3.2: Verify the build compiles with no errors**

```bash
cd apps/gdar_tv && ./gradlew assembleDebug 2>&1 | tail -20
```

Expected: `BUILD SUCCESSFUL` with no references to the now-private fields.

- [ ] **Step 3.3: Commit**

```bash
git add apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt
git commit -m "fix(tv): use getRmsSnapshot() in VisualizerPlugin; remove unsafe direct field access"
```

---

## Task 4: Dynamic `rmsBlockSize` from actual capture sample rate (Step 7)

**Files:**
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt`
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MainActivity.kt`

**Background:** `RMS_BLOCK_SIZE = 441` was hardcoded assuming 44100Hz. The requested device rate and the effective `AudioRecord` rate should be treated separately. Fix: accept a preferred `sampleRate: Int` in `start()`, request that rate when building `AudioRecord`, then read `record.sampleRate` after construction and derive `rmsBlockSize = effectiveSampleRate / 100` from that value. `MainActivity` still queries `AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE` and passes it as a preference.

- [ ] **Step 4.1: Remove `SAMPLE_RATE` companion const; add instance vars to StereoCapture**

In `StereoCapture.kt` companion object, remove:
```kotlin
private const val SAMPLE_RATE = 44100
```

Add two instance vars near the other private fields (around line 79 after previous tasks):
```kotlin
/** Sample rate used for the current capture session. Set in start(). */
private var capturedSampleRate = 44100

/**
 * Number of PCM frames per RMS block. Targets 10ms blocks → 100Hz RMS rate.
 * Derived as capturedSampleRate / 100 (e.g. 441 at 44100Hz, 480 at 48000Hz).
 */
private var rmsBlockSize = 441
```

- [ ] **Step 4.2: Update `start()` signature to accept a preferred `sampleRate`**

Change:
```kotlin
fun start(projection: MediaProjection): Boolean {
```
to:
```kotlin
fun start(projection: MediaProjection, sampleRate: Int = 44100): Boolean {
```

Inside `start()`, immediately after the `stop()` call, normalize the preferred value and set the instance vars:
```kotlin
val requestedSampleRate = sampleRate.takeIf { it > 0 } ?: 44100
capturedSampleRate = requestedSampleRate
rmsBlockSize = maxOf(1, requestedSampleRate / 100) // 10ms blocks → 100Hz RMS rate
```

Replace the two references to `SAMPLE_RATE` in `start()` with `requestedSampleRate`:

```kotlin
// getMinBufferSize call:
val minBuf = AudioRecord.getMinBufferSize(
    requestedSampleRate,
    channelConfig,
    encoding,
)

// AudioFormat builder:
AudioFormat.Builder()
    .setEncoding(encoding)
    .setSampleRate(requestedSampleRate)
    .setChannelMask(channelConfig)
    .build()
```

After `record.state` is validated, capture the effective sample rate and recompute `rmsBlockSize`:

```kotlin
capturedSampleRate = record.sampleRate.takeIf { it > 0 } ?: requestedSampleRate
rmsBlockSize = maxOf(1, capturedSampleRate / 100)
```

Update the start log line to include both requested and effective rates:
```kotlin
Log.i(
    TAG,
    "Starting stereo capture " +
        "(requestedSampleRate=$requestedSampleRate, " +
        "sampleRate=$capturedSampleRate, " +
        "rmsBlockSize=$rmsBlockSize, " +
        "minBuf=$minBuf, bufferSize=$bufferSize, ${deviceSummary()})",
)
```

- [ ] **Step 4.3: Use `rmsBlockSize` instance var in `processBuffer`**

Replace the hardcoded comparison:
```kotlin
// old:
if (rmsSamples >= RMS_BLOCK_SIZE) {
// new:
if (rmsSamples >= rmsBlockSize) {
```

- [ ] **Step 4.4: Remove old `RMS_BLOCK_SIZE` instance val**

Delete the line (originally line 80):
```kotlin
private val RMS_BLOCK_SIZE = 441 // 10ms at 44100Hz -> 100Hz RMS sample rate
```

- [ ] **Step 4.5: Update `resetAnalysisState()` to also reset `rmsBlockSize`**

In `resetAnalysisState()`, add at the end:
```kotlin
rmsBlockSize = capturedSampleRate / 100
```

This ensures if `stop()` is called and `capturedSampleRate` was set, the block size stays consistent on restart.

- [ ] **Step 4.6: Update `MainActivity.kt` to query preferred sample rate and pass it**

In `MainActivity.kt`, find the `stereoCapture.start(projection)` call (line 118):

```kotlin
// old:
val ok = stereoCapture.start(projection)

// new:
val preferredRate = (getSystemService(Context.AUDIO_SERVICE) as? AudioManager)
    ?.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)
    ?.toIntOrNull()
    ?: 44100
val ok = stereoCapture.start(projection, preferredRate)
```

Add the required import at the top of `MainActivity.kt` if not already present:
```kotlin
import android.media.AudioManager
```

- [ ] **Step 4.7: Verify the build compiles**

```bash
cd apps/gdar_tv && ./gradlew assembleDebug 2>&1 | tail -20
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4.8: Commit**

```bash
git add apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/StereoCapture.kt \
        apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/MainActivity.kt
git commit -m "fix(tv): compute rmsBlockSize dynamically from device sample rate (step 7)"
```

---

## Verification on Device

After all tasks are committed:

- [ ] Deploy to TV: `cd apps/gdar_tv && ./gradlew installDebug`
- [ ] Play music on TV, filter logcat: `adb logcat -s StereoCapture:D VisualizerPlugin:D`
- [ ] Confirm `Starting stereo capture (requestedSampleRate=..., sampleRate=..., rmsBlockSize=...)` appears in log
- [ ] Confirm beat detection still fires (look for autocorr BPM log lines in VisualizerPlugin)
- [ ] Confirm no `ArrayIndexOutOfBoundsException` or threading errors in logcat

---

## Self-Review Notes

- **Step 8 (Task 1)** — `rmsHistorySize` only appears in `StereoCapture.kt` (3x) and `VisualizerPlugin.kt` (1x); all covered.
- **Steps 5+6 (Tasks 2+3)** — `fullRmsHistory`, `rmsHistoryIndex`, `rmsHistoryCount` are all privatized; all RMS history read/write/reset paths share the same lock; `VisualizerPlugin` reader fully rewritten to use snapshot; the `fallbackRmsHistory` path (local to VisualizerPlugin, single-threaded) is correctly left unchanged.
- **Step 7 (Task 4)** — `SAMPLE_RATE` const removed; `capturedSampleRate` / `rmsBlockSize` instance vars added; the requested rate flows from `MainActivity`, `AudioRecord.sampleRate` is used as the effective rate after construction, `processBuffer` uses `rmsBlockSize`, and the start log prints both requested and effective values.
- No changes to `gdar_mobile` — confirmed mobile's `StereoCapture.kt` has no RMS history fields and mobile's `VisualizerPlugin.kt` has no references to them.
