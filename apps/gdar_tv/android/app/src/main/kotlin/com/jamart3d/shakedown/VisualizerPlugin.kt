package com.jamart3d.shakedown

import android.media.audiofx.Visualizer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt
import kotlin.math.max

/**
 * Android Visualizer API plugin for screensaver visualizer.
 *
 * Performs FFT analysis on audio output and sends frequency band energy
 * data to Flutter via EventChannel.
 *
 * Tuning knobs (set via 'updateConfig' method call from Flutter):
 *   peakDecay          (0.990–0.999) How slowly peaks decay. Higher = slower adaptation.
 *   bassBoost          (1.0–3.0)     Visual-only bass gain before display smoothing.
 *   reactivityStrength (0.5–2.0)     Global scale applied to all bands before sending to Flutter.
 *   beatDetectorMode   (auto/hybrid/bass/mid/broad/pcm) Selects the final beat source.
 *   beatSensitivity    (0.0–1.0)     Beat detector sensitivity. Higher = fires more easily.
 *
 * Beat detection: normalised-band adaptive threshold (6 parallel algorithms).
 *   Uses peak-normalised band values (not spectral flux) because this chipset
 *   returns near-identical FFT frames every callback, making flux always ~0.
 *   Each algorithm compares a normed signal against a rolling mean and fires
 *   isBeat when the signal spikes above mean × threshold.
 *   Current detector order:
 *     0 BASS   bass band vs rolling mean
 *     1 MID    mid band vs rolling mean
 *     2 BROAD  (bass + mid) / 2 vs rolling mean
 *     3 ALL    all-band onset vs rolling mean
 *     4 EMA    mid band vs EMA background
 *     5 TREB   treble band vs rolling mean
 *   Final isBeat is produced by a preferred timing source:
 *     - PCM onset when StereoCapture is active and warmed up
 *     - otherwise the Visualizer hybrid onset score built from low-band onset,
 *       mid-band onset, and positive broadband flux
 */
class VisualizerPlugin(
    private val stereoCapture: StereoCapture,
) : MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "VisualizerPlugin"
        private const val METHOD_CHANNEL = "shakedown/visualizer"
        private const val EVENT_CHANNEL = "shakedown/visualizer_events"

        // Capture rate is set dynamically via Visualizer.getMaxCaptureRate() (millihertz).

        // Smoothing: 60% old value, 40% new — fixed, not user-configurable
        private const val SMOOTHING = 0.6

        private const val PEAK_FLOOR = 0.01

        // 8-band frequency cutoffs (Hz)
        private val BAND_CUTOFFS = doubleArrayOf(60.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 20000.0)

        // Beat detection: minimum gap between detected beats per algorithm (ms).
        // 200ms = max 5 beats/sec, allows 4/4 at up to 150 BPM.
        private const val MIN_BEAT_GAP_MS = 200L

        // Signal history sizes for adaptive beat thresholds.
        private const val FLUX_HISTORY_SIZE = 20      // ~1s at 20 Hz
        private const val TRACKING_HISTORY_SIZE = 8

        // Number of beat-detection algorithms run in parallel (for beat_debug mode).
        private const val NUM_BEAT_ALGOS = 6

        // Oscilloscope: number of PCM points sent to Flutter per frame.
        private const val WAVEFORM_POINTS = 256

        // Noise gate: energy below this is treated as silence (0.01 = 1% volume)
        private const val SILENCE_THRESHOLD = 0.01

        // Zero-FFT watchdog threshold: ~2s at 20 Hz capture rate
        private const val ZERO_FRAME_THRESHOLD = 40
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var autocorrSecondPass = false
    private var autocorrSecondPassHq = false
    private val isSabrinaDevice = Build.DEVICE.lowercase() == "sabrina"
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRunning = false
    private var currentAudioSessionId = 0

    // Zero-FFT watchdog: if we get ~2s of silence while supposedly running,
    // try reinitializing with session 0 (global mix) as fallback.
    private var consecutiveZeroFrames = 0
    private var hasTriedFallbackSession = false

    // Smoothed values carried between frames (3-band legacy)
    private var smoothBass = 0.0
    private var smoothMid = 0.0
    private var smoothTreble = 0.0

    // Smoothed 8-band values
    private val smoothBands = DoubleArray(8)

    // Rolling peaks for display normalization (3-band visual path)
    private var peakBass = PEAK_FLOOR
    private var peakMid = PEAK_FLOOR
    private var peakTreble = PEAK_FLOOR

    // Separate detector peak so beat logic stays independent from visual bass gain.
    private var detectorPeakBass = PEAK_FLOOR

    // Rolling peaks for 8-band normalization
    private val peakBands = DoubleArray(8) { PEAK_FLOOR }

    // Tuning knobs — updated live from Flutter settings
    private var peakDecay = 0.998
    private var bassBoost = 1.0
    private var reactivityStrength = 1.0
    private var beatDetectorMode = "auto"
    private var beatSensitivity = 0.5

    // ── Multi-algorithm beat detection state ─────────────────────────────────
    // Histories for the 6 parallel algorithms — each tracks a different signal.
    private val bassHistory    = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // 0 BASS
    private val midHistory     = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // 1 MID
    private val broadHistory   = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // 2 BROAD
    private val allHistory     = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // 3 ALL
    private val trebleHistory  = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // 5 TREB
    private var midEmaVal      = 0.0                                        // EMA on mid
    private val midEmaWarmup   = ArrayDeque<Double>(10)                     // EMA warmup
    private val hybridHistory  = ArrayDeque<Double>(FLUX_HISTORY_SIZE)      // warmup / future robust baseline
    private var hybridBaselineVal = 0.0
    private var hybridFloorVal    = 0.0
    private var lowFastVal     = 0.0
    private var lowSlowVal     = 0.0
    private var midFastVal     = 0.0
    private var midSlowVal     = 0.0
    private var prevAllVal     = 0.0
    private var hybridLastBeatMs = 0L
    private var pcmBaselineVal = 0.0
    private var pcmFloorVal    = 0.0
    private var pcmLastBeatMs  = 0L
    private val trackedBeatIntervalsMs = ArrayDeque<Double>(TRACKING_HISTORY_SIZE)
    private var trackedIbiMs = 0.0
    private var trackedLastBeatMs = 0L

    // Independent last-beat timestamps so algorithms don't suppress each other.
    private val lastBeatMs = LongArray(NUM_BEAT_ALGOS)

    // Latest downsampled PCM waveform for the oscilloscope display.
    // Written by onWaveFormDataCapture, read by processFftData (same thread).
    private var pendingWaveform: List<Float> = emptyList()

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> result.success(isVisualizerAvailable())
            "initialize" -> {
                val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                result.success(initialize(audioSessionId))
            }
            "start" -> {
                Log.i(TAG, "MethodChannel start received")
                start()
                result.success(true)
            }
            "stop" -> { stop(); result.success(true) }
            "release" -> { release(); result.success(true) }
            "updateConfig" -> {
                // Receive tuning knobs from Flutter settings in real time
                peakDecay = call.argument<Double>("peakDecay") ?: peakDecay
                bassBoost = call.argument<Double>("bassBoost") ?: bassBoost
                reactivityStrength = call.argument<Double>("reactivityStrength") ?: reactivityStrength
                beatDetectorMode = call.argument<String>("beatDetectorMode") ?: beatDetectorMode
                beatSensitivity = call.argument<Double>("beatSensitivity") ?: beatSensitivity
                autocorrSecondPass = call.argument<Boolean>("autocorrSecondPass") ?: autocorrSecondPass
                val requestedHq = call.argument<Boolean>("autocorrSecondPassHq") ?: autocorrSecondPassHq
                autocorrSecondPassHq = if (isSabrinaDevice) false else requestedHq
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i(TAG, "EventChannel onListen")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.i(TAG, "EventChannel onCancel")
        eventSink = null
    }

    private fun isVisualizerAvailable(): Boolean {
        return try {
            val testVisualizer = Visualizer(0)
            testVisualizer.release()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Visualizer not available: ${e.message}")
            false
        }
    }

    private fun initialize(audioSessionId: Int): Boolean {
        return try {
            release()
            currentAudioSessionId = audioSessionId
            consecutiveZeroFrames = 0
            hasTriedFallbackSession = false
            visualizer = Visualizer(audioSessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
                val maxRate = Visualizer.getMaxCaptureRate() // millihertz, typically 20000 mHz = 20 Hz
                setDataCaptureListener(
                    object : Visualizer.OnDataCaptureListener {
                        override fun onWaveFormDataCapture(
                            visualizer: Visualizer?, waveform: ByteArray?, samplingRate: Int
                        ) {
                            waveform?.let { pendingWaveform = downsampleWaveform(it) }
                        }

                        override fun onFftDataCapture(
                            visualizer: Visualizer?, fft: ByteArray?, samplingRate: Int
                        ) {
                            fft?.let { processFftData(it, samplingRate) }
                        }
                    },
                    maxRate,
                    true,  // waveform enabled (oscilloscope)
                    true   // fft enabled
                )
            }
            Log.d(TAG, "Visualizer initialized with session ID: $audioSessionId")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize visualizer: ${e.message}")
            false
        }
    }

    private fun start() {
        try {
            // Reset state on start
            smoothBass = 0.0; smoothMid = 0.0; smoothTreble = 0.0
            peakBass = PEAK_FLOOR; peakMid = PEAK_FLOOR; peakTreble = PEAK_FLOOR
            detectorPeakBass = PEAK_FLOOR
            smoothBands.fill(0.0)
            peakBands.fill(PEAK_FLOOR)
            lastBeatMs.fill(0L)
            bassHistory.clear();   midHistory.clear()
            broadHistory.clear();  allHistory.clear()
            trebleHistory.clear()
            midEmaVal = 0.0;       midEmaWarmup.clear()
            hybridHistory.clear()
            hybridBaselineVal = 0.0
            hybridFloorVal = 0.0
            lowFastVal = 0.0;      lowSlowVal = 0.0
            midFastVal = 0.0;      midSlowVal = 0.0
            prevAllVal = 0.0
            hybridLastBeatMs = 0L
            pcmBaselineVal = 0.0
            pcmFloorVal = 0.0
            pcmLastBeatMs = 0L
            trackedBeatIntervalsMs.clear()
            trackedIbiMs = 0.0
            trackedLastBeatMs = 0L

            visualizer?.enabled = true
            isRunning = true
            Log.d(TAG, "Visualizer started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start visualizer: ${e.message}")
        }
    }

    private fun stop() {
        try {
            visualizer?.enabled = false
            isRunning = false
            Log.d(TAG, "Visualizer stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop visualizer: ${e.message}")
        }
    }

    private fun release() {
        try {
            stop()
            visualizer?.release()
            visualizer = null
            Log.d(TAG, "Visualizer released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release visualizer: ${e.message}")
        }
    }

    private fun downsampleWaveform(waveform: ByteArray): List<Float> {
        val result = ArrayList<Float>(WAVEFORM_POINTS)
        val step = waveform.size.toDouble() / WAVEFORM_POINTS

        for (i in 0 until WAVEFORM_POINTS) {
            val idx = (i * step).toInt().coerceIn(0, waveform.size - 1)
            // Convert unsigned 8-bit (0-255, centre=128) to signed -1.0..1.0
            val normalized = ((waveform[idx].toInt() and 0xFF) - 128) / 128.0f
            result.add(normalized)
        }

        return result
    }

    private fun processFftData(fft: ByteArray, samplingRate: Int) {
        if (eventSink == null) return

        val numFrequencies = fft.size / 2
        // samplingRate is in milliHertz, so we divide by 1000 to get standard Hz
        val frequencyResolution = (samplingRate / 1000.0) / 2.0 / numFrequencies

        // ── Legacy 3-band accumulation ──────────────────────────────────
        var bassSum = 0.0; var midSum = 0.0; var trebleSum = 0.0
        var bassCount = 0; var midCount = 0; var trebleCount = 0

        // ── 8-band accumulation ─────────────────────────────────────────
        val bandSums = DoubleArray(8)
        val bandCounts = IntArray(8)

        for (i in 1 until numFrequencies) {
            val frequency = i * frequencyResolution
            val real = fft[i * 2].toInt()
            val imaginary = fft[i * 2 + 1].toInt()
            val magnitudeSquared = (real * real + imaginary * imaginary).toDouble()

            // Legacy 3-band
            when {
                frequency < 250.0 -> { bassSum += magnitudeSquared; bassCount++ }
                frequency < 4000.0 -> { midSum += magnitudeSquared; midCount++ }
                else -> { trebleSum += magnitudeSquared; trebleCount++ }
            }

            // 8-band: find which band this frequency belongs to
            val bandIdx = BAND_CUTOFFS.indexOfFirst { frequency < it }.let { if (it == -1) 7 else it }
            bandSums[bandIdx] += magnitudeSquared
            bandCounts[bandIdx]++
        }

        // ── Legacy 3-band processing ────────────────────────────────────
        val detectorRawBass = if (bassCount > 0) sqrt(bassSum / bassCount) / 128.0 else 0.0
        val rawMid = if (midCount > 0) sqrt(midSum / midCount) / 128.0 else 0.0
        val rawTreble = if (trebleCount > 0) sqrt(trebleSum / trebleCount) / 128.0 else 0.0

        // ── Zero-FFT watchdog ──────────────────────────────────────────
        if (detectorRawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD) {
            consecutiveZeroFrames++
            if (consecutiveZeroFrames == ZERO_FRAME_THRESHOLD && !hasTriedFallbackSession && currentAudioSessionId != 0) {
                hasTriedFallbackSession = true
                Log.w(TAG, "Watchdog: $ZERO_FRAME_THRESHOLD consecutive zero-FFT frames with session $currentAudioSessionId. Retrying with session 0 (global mix).")
                try {
                    visualizer?.enabled = false
                    visualizer?.release()
                    visualizer = Visualizer(0).apply {
                        captureSize = Visualizer.getCaptureSizeRange()[1]
                        val maxRate = Visualizer.getMaxCaptureRate()
                        setDataCaptureListener(
                            object : Visualizer.OnDataCaptureListener {
                                override fun onWaveFormDataCapture(v: Visualizer?, wf: ByteArray?, sr: Int) {
                                    wf?.let { pendingWaveform = downsampleWaveform(it) }
                                }
                                override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, sr: Int) {
                                    fft?.let { processFftData(it, sr) }
                                }
                            },
                            maxRate, true, true
                        )
                        enabled = true
                    }
                    currentAudioSessionId = 0
                    consecutiveZeroFrames = 0
                    Log.d(TAG, "Watchdog: Reinitialized with session 0")
                } catch (e: Exception) {
                    Log.e(TAG, "Watchdog: Failed to reinitialize: ${e.message}")
                }
                return
            }
        } else {
            consecutiveZeroFrames = 0
        }

        // Visual-only bass gain. Beat detection must stay on pre-boost bass energy.
        val visualRawBass = (detectorRawBass * bassBoost).coerceIn(0.0, 2.0)

        // Update rolling peaks using the user-controlled decay rate
        // If the signal is pure silence, we eventually reset peaks to PEAK_FLOOR
        // to prevent normalization artifacts when music starts again.
        if (visualRawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD) {
            peakBass = max(peakBass * peakDecay, PEAK_FLOOR)
            peakMid = max(peakMid * peakDecay, PEAK_FLOOR)
            peakTreble = max(peakTreble * peakDecay, PEAK_FLOOR)
        } else {
            peakBass = max(peakBass * peakDecay, max(visualRawBass, PEAK_FLOOR))
            peakMid = max(peakMid * peakDecay, max(rawMid, PEAK_FLOOR))
            peakTreble = max(peakTreble * peakDecay, max(rawTreble, PEAK_FLOOR))
        }

        // Detector bass peak stays on pre-boost energy so beat rate is independent from bassBoost.
        if (detectorRawBass < SILENCE_THRESHOLD) {
            detectorPeakBass = max(detectorPeakBass * peakDecay, PEAK_FLOOR)
        } else {
            detectorPeakBass = max(detectorPeakBass * peakDecay, max(detectorRawBass, PEAK_FLOOR))
        }

        // Normalize against peak, applying noise gate (hard floor).
        val visualNormalizedBass =
            if (visualRawBass < SILENCE_THRESHOLD) 0.0 else (visualRawBass / peakBass).coerceIn(0.0, 1.0)
        val normalizedMid =
            if (rawMid < SILENCE_THRESHOLD) 0.0 else (rawMid / peakMid).coerceIn(0.0, 1.0)
        val normalizedTreble =
            if (rawTreble < SILENCE_THRESHOLD) 0.0 else (rawTreble / peakTreble).coerceIn(0.0, 1.0)
        val detectorNormalizedBass =
            if (detectorRawBass < SILENCE_THRESHOLD) 0.0 else (detectorRawBass / detectorPeakBass).coerceIn(0.0, 1.0)

        // Exponential smoothing to kill jitter
        smoothBass = smoothBass * SMOOTHING + visualNormalizedBass * (1.0 - SMOOTHING)
        smoothMid = smoothMid * SMOOTHING + normalizedMid * (1.0 - SMOOTHING)
        smoothTreble = smoothTreble * SMOOTHING + normalizedTreble * (1.0 - SMOOTHING)

        // Apply overall reactivity strength scaling
        val finalBass = (smoothBass * reactivityStrength).coerceIn(0.0, 1.0)
        val finalMid = (smoothMid * reactivityStrength).coerceIn(0.0, 1.0)
        val finalTreble = (smoothTreble * reactivityStrength).coerceIn(0.0, 1.0)
        val overall = (finalBass + finalMid + finalTreble) / 3.0

        // ── 8-band processing ───────────────────────────────────────────
        val isSilent = visualRawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD
        val finalBands = DoubleArray(8)
        for (b in 0 until 8) {
            val rawBand = if (bandCounts[b] > 0) sqrt(bandSums[b] / bandCounts[b]) / 128.0 else 0.0
            // Mirror the 3-band silence gating: decay peaks during silence
            if (isSilent) {
                peakBands[b] = max(peakBands[b] * peakDecay, PEAK_FLOOR)
            } else {
                peakBands[b] = max(peakBands[b] * peakDecay, max(rawBand, PEAK_FLOOR))
            }
            // Use global silence flag rather than per-band gate: individual narrow
            // bands have fewer FFT bins than the 3-band buckets, so their raw
            // values are smaller even when music is playing.
            val normalized = if (isSilent) 0.0 else (rawBand / peakBands[b]).coerceIn(0.0, 1.0)
            smoothBands[b] = smoothBands[b] * SMOOTHING + normalized * (1.0 - SMOOTHING)
            finalBands[b] = (smoothBands[b] * reactivityStrength).coerceIn(0.0, 1.0)
        }

        // ── 6-algorithm parallel beat detection ──────────────────────────────
        // Uses pre-smoothing detector values. Bass stays on pre-boost energy so
        // beat frequency does not change when the user only raises visual gain.
        //
        // NOTE: on some TV chipsets the sub-bass and bass FFT bins return near-zero
        // energy even during loud music — detectorNormalizedBass can therefore be 0 while
        // normalizedMid and normalizedTreble are healthy.  We therefore spread the
        // 6 algorithms across bass, mid, treble, and combined signals so at least
        // some of them will respond on any hardware.
        //
        // Signals used:
        //   sig0 = detectorNormalizedBass            (0–250 Hz)
        //   sig1 = normalizedMid                     (250–4000 Hz)
        //   sig2 = normalizedTreble                  (4000+ Hz)
        //   sig3 = (detectorNormalizedBass + normalizedMid)/2 (broadband)
        //   sig4 = (sig0+sig1+sig2)/3                (all-band onset)

        val sig0 = detectorNormalizedBass
        val sig1 = normalizedMid
        val sig2 = normalizedTreble
        val sig3 = (sig0 + sig1) / 2.0
        val sig4 = (sig0 + sig1 + sig2) / 3.0

        fun <T> ArrayDeque<T>.pushCapped(v: T, cap: Int) { addLast(v); if (size > cap) removeFirst() }

        // EMA background for mid (α=0.15 → ~150ms half-life at 20 Hz).
        midEmaWarmup.pushCapped(sig1, 10)
        midEmaVal = midEmaVal * 0.85 + sig1 * 0.15

        // Fast/slow envelope followers plus positive broadband flux for the
        // hybrid final beat decision.
        lowFastVal = lowFastVal * 0.55 + sig0 * 0.45
        lowSlowVal = lowSlowVal * 0.90 + sig0 * 0.10
        midFastVal = midFastVal * 0.60 + sig1 * 0.40
        midSlowVal = midSlowVal * 0.92 + sig1 * 0.08
        val lowOnset = max(0.0, lowFastVal - lowSlowVal)
        val midOnset = max(0.0, midFastVal - midSlowVal)
        val broadFlux = max(0.0, sig4 - prevAllVal)
        prevAllVal = sig4

        // Populate per-algorithm histories.
        bassHistory.pushCapped(sig0,   FLUX_HISTORY_SIZE)
        midHistory.pushCapped(sig1,    FLUX_HISTORY_SIZE)
        broadHistory.pushCapped(sig3,  FLUX_HISTORY_SIZE)
        allHistory.pushCapped(sig4,    FLUX_HISTORY_SIZE)
        trebleHistory.pushCapped(sig2, FLUX_HISTORY_SIZE)

        val nowMs = SystemClock.elapsedRealtime()

        // Helper: compute the current signal-to-baseline ratio for debug display.
        fun scoreVsMean(signal: Double, history: ArrayDeque<Double>): Double {
            if (history.size < 10 || signal < SILENCE_THRESHOLD) return 0.0
            val mean = history.average()
            if (mean <= 0.0) return 0.0
            return signal / mean
        }

        fun scoreVsEma(signal: Double, baseline: Double, warmupReady: Boolean): Double {
            if (!warmupReady || signal < SILENCE_THRESHOLD || baseline <= 0.0) return 0.0
            return signal / baseline
        }

        fun meanOrZero(history: ArrayDeque<Double>): Double {
            if (history.size < 10) return 0.0
            return history.average()
        }

        fun median(values: List<Double>): Double {
            if (values.isEmpty()) return 0.0
            val sorted = values.sorted()
            val mid = sorted.size / 2
            return if (sorted.size % 2 == 0) {
                (sorted[mid - 1] + sorted[mid]) / 2.0
            } else {
                sorted[mid]
            }
        }

        // Helper: fire when signal spikes above rolling mean × multiplier.
        fun normBeat(signal: Double, history: ArrayDeque<Double>, multiplier: Double, algoIdx: Int): Boolean {
            if (history.size < 10 || signal < SILENCE_THRESHOLD) return false
            val mean = history.average()
            if (mean <= 0.0 || signal <= mean * multiplier) return false
            if ((nowMs - lastBeatMs[algoIdx]) < MIN_BEAT_GAP_MS) return false
            lastBeatMs[algoIdx] = nowMs
            return true
        }

        // sensitivity 1.0 → 1.2× mean  |  sensitivity 0.0 → 2.2× mean
        val adaptiveMultiplier = 1.2 + (1.0 - beatSensitivity) * 1.0
        val hybridThresholdRatio = 1.10 + (1.0 - beatSensitivity) * 0.70

        val hybridScore =
            (lowOnset * 0.45) +
            (midOnset * 0.35) +
            (broadFlux * 0.20)
        val hybridHasSignal =
            sig0 > SILENCE_THRESHOLD ||
            sig1 > SILENCE_THRESHOLD ||
            sig4 > SILENCE_THRESHOLD
        val hybridBaseline = hybridBaselineVal
        val hybridFloor = hybridFloorVal
        val hybridThresholdFloor = 0.015 + (1.0 - beatSensitivity) * 0.02
        val beatThreshold = max(
            hybridBaseline * hybridThresholdRatio,
            hybridFloor + hybridThresholdFloor,
        )
        val hybridConfidence =
            if (beatThreshold > 0.0) (hybridScore / beatThreshold).coerceIn(0.0, 1.0)
            else 0.0
        val hybridIsBeat =
            hybridHistory.size >= 10 &&
            hybridHasSignal &&
            hybridScore > beatThreshold &&
            (nowMs - hybridLastBeatMs) > MIN_BEAT_GAP_MS
        if (hybridIsBeat) hybridLastBeatMs = nowMs
        hybridHistory.pushCapped(hybridScore, FLUX_HISTORY_SIZE)
        if (hybridHasSignal) {
            hybridBaselineVal =
                if (hybridBaselineVal <= 0.0) hybridScore
                else hybridBaselineVal * 0.94 + hybridScore * 0.06
            hybridFloorVal =
                if (hybridFloorVal <= 0.0) hybridScore
                else if (hybridScore < hybridFloorVal) {
                    hybridFloorVal * 0.80 + hybridScore * 0.20
                } else {
                    hybridFloorVal * 0.995 + hybridScore * 0.005
                }
        } else {
            hybridBaselineVal *= 0.96
            hybridFloorVal *= 0.96
        }

        val pcmWaveformL = stereoCapture.waveformL
        val pcmWaveformR = stereoCapture.waveformR
        val pcmAgeMs =
            if (stereoCapture.lastAnalysisMs > 0L) {
                (nowMs - stereoCapture.lastAnalysisMs).coerceAtLeast(0L).toDouble()
            } else {
                null
            }
        val pcmFresh =
            stereoCapture.lastAnalysisMs > 0L &&
            (nowMs - stereoCapture.lastAnalysisMs) <= 500L
        val hasStereoPcm =
            stereoCapture.isActive &&
            pcmWaveformL.isNotEmpty() &&
            pcmWaveformR.isNotEmpty() &&
            pcmFresh
        val pcmLevel =
            if (hasStereoPcm) stereoCapture.monoLevelRms.coerceIn(0.0, 1.0)
            else 0.0
        val pcmOnset =
            if (hasStereoPcm) stereoCapture.monoOnset.coerceAtLeast(0.0)
            else 0.0
        val pcmFlux =
            if (hasStereoPcm) stereoCapture.monoFlux.coerceAtLeast(0.0)
            else 0.0
        val pcmScore = (pcmOnset * 0.70) + (pcmFlux * 0.30)
        val pcmHasSignal = hasStereoPcm && (pcmLevel > 0.003 || pcmOnset > 0.001)
        val pcmWarmupReady = hasStereoPcm && stereoCapture.analysisFrames >= 12
        val pcmThresholdRatio = 1.05 + (1.0 - beatSensitivity) * 0.55
        val pcmThresholdFloor = 0.0025 + (1.0 - beatSensitivity) * 0.008
        val pcmBaseline = pcmBaselineVal
        val pcmFloor = pcmFloorVal
        val pcmThreshold = max(
            pcmBaseline * pcmThresholdRatio,
            pcmFloor + pcmThresholdFloor,
        )
        val pcmConfidence =
            if (pcmThreshold > 0.0) (pcmScore / pcmThreshold).coerceIn(0.0, 1.0)
            else 0.0
        val pcmIsBeat =
            pcmWarmupReady &&
            pcmHasSignal &&
            pcmScore > pcmThreshold &&
            (nowMs - pcmLastBeatMs) > MIN_BEAT_GAP_MS
        if (pcmIsBeat) pcmLastBeatMs = nowMs
        if (hasStereoPcm) {
            if (pcmHasSignal) {
                pcmBaselineVal =
                    if (pcmBaselineVal <= 0.0) pcmScore
                    else pcmBaselineVal * 0.92 + pcmScore * 0.08
                pcmFloorVal =
                    if (pcmFloorVal <= 0.0) pcmScore
                    else if (pcmScore < pcmFloorVal) {
                        pcmFloorVal * 0.75 + pcmScore * 0.25
                    } else {
                        pcmFloorVal * 0.995 + pcmScore * 0.005
                    }
            } else {
                pcmBaselineVal *= 0.96
                pcmFloorVal *= 0.96
            }
        } else {
            pcmBaselineVal *= 0.92
            pcmFloorVal *= 0.92
        }

        val beats = BooleanArray(NUM_BEAT_ALGOS)
        // 0 BASS   – pre-boost bass vs 20-frame mean
        beats[0] = normBeat(sig0, bassHistory, adaptiveMultiplier, 0)
        // 1 MID    – normalizedMid vs 20-frame mean
        beats[1] = normBeat(sig1, midHistory, adaptiveMultiplier, 1)
        // 2 BROAD  – (bass+mid)/2 vs 20-frame mean
        beats[2] = normBeat(sig3, broadHistory, adaptiveMultiplier, 2)
        // 3 ALL    – all-band onset vs 20-frame mean
        beats[3] = normBeat(sig4, allHistory, adaptiveMultiplier, 3)
        // 4 EMA    – normalizedMid vs its own EMA background (classic onset)
        beats[4] = midEmaWarmup.size >= 10 &&
                   midEmaVal > SILENCE_THRESHOLD &&
                   sig1 > midEmaVal * (1.0 + (1.0 - beatSensitivity) * 0.5) &&
                   (nowMs - lastBeatMs[4]) > MIN_BEAT_GAP_MS
        if (beats[4]) lastBeatMs[4] = nowMs
        // 5 TREB   – normalizedTreble vs 20-frame mean
        beats[5] = normBeat(sig2, trebleHistory, adaptiveMultiplier, 5)

        val emaThresholdRatio = 1.0 + (1.0 - beatSensitivity) * 0.5
        val bassScore = scoreVsMean(sig0, bassHistory).coerceIn(0.0, 3.0)
        val midScore = scoreVsMean(sig1, midHistory).coerceIn(0.0, 3.0)
        val broadScore = scoreVsMean(sig3, broadHistory).coerceIn(0.0, 3.0)
        val allScore = scoreVsMean(sig4, allHistory).coerceIn(0.0, 3.0)
        val emaScore =
            scoreVsEma(sig1, midEmaVal, midEmaWarmup.size >= 10).coerceIn(0.0, 3.0)
        val trebleScore = scoreVsMean(sig2, trebleHistory).coerceIn(0.0, 3.0)

        data class DetectorSelection(
            val isBeat: Boolean,
            val score: Double,
            val threshold: Double,
            val confidence: Double,
            val source: String,
        )

        fun scoreConfidence(score: Double, threshold: Double): Double {
            if (threshold <= 0.0) return 0.0
            return (score / threshold).coerceIn(0.0, 1.0)
        }

        val preferPcmBeat = pcmWarmupReady && pcmHasSignal
        val selectedMode = beatDetectorMode.lowercase()
        val selection = when (selectedMode) {
            "bass" -> DetectorSelection(
                isBeat = beats[0],
                score = bassScore,
                threshold = adaptiveMultiplier,
                confidence = scoreConfidence(bassScore, adaptiveMultiplier),
                source = "BASS",
            )
            "mid" -> DetectorSelection(
                isBeat = beats[1],
                score = midScore,
                threshold = adaptiveMultiplier,
                confidence = scoreConfidence(midScore, adaptiveMultiplier),
                source = "MID",
            )
            "broad" -> DetectorSelection(
                isBeat = beats[2],
                score = broadScore,
                threshold = adaptiveMultiplier,
                confidence = scoreConfidence(broadScore, adaptiveMultiplier),
                source = "BROAD",
            )
            "pcm" ->
                if (preferPcmBeat) {
                    DetectorSelection(
                        isBeat = pcmIsBeat,
                        score = pcmScore,
                        threshold = pcmThreshold,
                        confidence = pcmConfidence,
                        source = "PCM",
                    )
                } else {
                    DetectorSelection(
                        isBeat = hybridIsBeat,
                        score = hybridScore,
                        threshold = beatThreshold,
                        confidence = hybridConfidence,
                        source = "HYBRID",
                    )
                }
            "hybrid" -> DetectorSelection(
                isBeat = hybridIsBeat,
                score = hybridScore,
                threshold = beatThreshold,
                confidence = hybridConfidence,
                source = "HYBRID",
            )
            else ->
                if (preferPcmBeat) {
                    DetectorSelection(
                        isBeat = pcmIsBeat,
                        score = pcmScore,
                        threshold = pcmThreshold,
                        confidence = pcmConfidence,
                        source = "PCM",
                    )
                } else {
                    DetectorSelection(
                        isBeat = hybridIsBeat,
                        score = hybridScore,
                        threshold = beatThreshold,
                        confidence = hybridConfidence,
                        source = "HYBRID",
                    )
                }
        }
        val isBeat = selection.isBeat
        val finalBeatScore = selection.score
        val finalBeatThreshold = selection.threshold
        val finalBeatConfidence = selection.confidence
        val finalBeatSource = selection.source

        if (isBeat) {
            if (trackedLastBeatMs > 0L) {
                val intervalMs = (nowMs - trackedLastBeatMs).toDouble()
                when {
                    intervalMs in 250.0..1500.0 -> {
                        trackedBeatIntervalsMs.pushCapped(intervalMs, TRACKING_HISTORY_SIZE)
                        trackedIbiMs =
                            if (trackedIbiMs <= 0.0) intervalMs
                            else trackedIbiMs * 0.70 + intervalMs * 0.30
                    }
                    intervalMs > 1500.0 -> {
                        trackedBeatIntervalsMs.clear()
                        trackedIbiMs = 0.0
                    }
                }
            }
            trackedLastBeatMs = nowMs
        }

        val trackingAgeMs =
            if (trackedLastBeatMs > 0L) (nowMs - trackedLastBeatMs).coerceAtLeast(0L).toDouble()
            else Double.POSITIVE_INFINITY
        val trackingMedianIbi =
            if (trackedBeatIntervalsMs.isNotEmpty()) median(trackedBeatIntervalsMs.toList())
            else 0.0
        if (trackingMedianIbi > 0.0) {
            trackedIbiMs =
                if (trackedIbiMs <= 0.0) trackingMedianIbi
                else trackedIbiMs * 0.80 + trackingMedianIbi * 0.20
        }

        var trackedBeatBpm: Double? = null
        var trackedBeatIbiMs: Double? = null
        var trackedBeatPhase: Double? = null
        var trackedNextBeatMs: Double? = null
        var trackedGridConfidence: Double? = null
        if (trackedBeatIntervalsMs.size >= 3 &&
            trackedIbiMs > 0.0 &&
            trackedLastBeatMs > 0L &&
            trackingAgeMs <= trackedIbiMs * 3.0
        ) {
            val intervalValues = trackedBeatIntervalsMs.toList()
            val intervalMean = intervalValues.average()
            val variance = intervalValues.fold(0.0) { acc, value ->
                val delta = value - intervalMean
                acc + delta * delta
            } / intervalValues.size.toDouble()
            val intervalStdDev = sqrt(variance)
            val jitterRatio = if (intervalMean > 0.0) intervalStdDev / intervalMean else 1.0
            val stability = (1.0 - (jitterRatio / 0.18)).coerceIn(0.0, 1.0)
            val warmup =
                (intervalValues.size / TRACKING_HISTORY_SIZE.toDouble()).coerceIn(0.0, 1.0)
            val freshness =
                (1.0 - ((trackingAgeMs / (trackedIbiMs * 2.0)) - 0.5)).coerceIn(0.0, 1.0)
            val gridConfidence = (stability * warmup * freshness).coerceIn(0.0, 1.0)

            trackedBeatBpm = (60000.0 / trackedIbiMs).coerceIn(0.0, 400.0)
            trackedBeatIbiMs = trackedIbiMs.coerceIn(0.0, 5000.0)
            trackedGridConfidence = gridConfidence

            if (gridConfidence > 0.0) {
                val cycleOffsetMs = trackingAgeMs % trackedIbiMs
                trackedBeatPhase = (cycleOffsetMs / trackedIbiMs).coerceIn(0.0, 1.0)
                trackedNextBeatMs = (trackedIbiMs - cycleOffsetMs).coerceIn(0.0, 5000.0)
            }
        }

        if (isBeat) {
            Log.d(
                TAG,
                "BEAT src=%s score=%.3f thr=%.3f conf=%.3f vis=%.3f pcm=%.3f".format(
                    finalBeatSource,
                    finalBeatScore,
                    finalBeatThreshold,
                    finalBeatConfidence,
                    hybridScore,
                    pcmScore,
                )
            )
            Log.d(
                TAG,
                "BEAT detail visBase=%.3f visFloor=%.3f low=%.3f mid=%.3f flux=%.3f pcmBase=%.3f pcmFloor=%.3f pcmLvl=%.3f pcmOn=%.3f pcmFx=%.3f".format(
                    hybridBaseline,
                    hybridFloor,
                    lowOnset,
                    midOnset,
                    broadFlux,
                    pcmBaseline,
                    pcmFloor,
                    pcmLevel,
                    pcmOnset,
                    pcmFlux,
                )
            )
        }

        val algoSignals = doubleArrayOf(
            sig0, // 0 BASS
            sig1, // 1 MID
            sig3, // 2 BROAD
            sig4, // 3 ALL
            sig1, // 4 EMA (same input signal as MID, different baseline)
            sig2, // 5 TREB
        )
        val algoBaselines = doubleArrayOf(
            meanOrZero(bassHistory),                                  // 0 BASS
            meanOrZero(midHistory),                                   // 1 MID
            meanOrZero(broadHistory),                                 // 2 BROAD
            meanOrZero(allHistory),                                   // 3 ALL
            if (midEmaWarmup.size >= 10) midEmaVal else 0.0,          // 4 EMA
            meanOrZero(trebleHistory),                                // 5 TREB
        )
        val algoThresholds = doubleArrayOf(
            adaptiveMultiplier, // 0 BASS
            adaptiveMultiplier, // 1 MID
            adaptiveMultiplier, // 2 BROAD
            adaptiveMultiplier, // 3 ALL
            emaThresholdRatio,  // 4 EMA
            adaptiveMultiplier, // 5 TREB
        )

        // Per-algorithm diagnostic scores used by beat_debug.
        // Mean-window variants report signal / rolling mean.
        // EMA reports signal / EMA baseline.
        val algoLevels = doubleArrayOf(
            bassScore,   // 0 BASS
            midScore,    // 1 MID
            broadScore,  // 2 BROAD
            allScore,    // 3 ALL
            emaScore,    // 4 EMA
            trebleScore, // 5 TREB
        )
        val winningAlgoId = algoLevels.indices.maxByOrNull { algoLevels[it] }
            ?.takeIf { algoLevels[it] > 0.0 }
            ?: -1

        // ── Auto-correlation Beat Detection ──────────────────────────────────────
        var autocorrBpm: Double? = null
        var autocorrIbiMs: Double? = null

        val useStereoRms = hasStereoPcm && stereoCapture.rmsHistoryCount >= 200

        if (useStereoRms) {
            // Cap to 256 samples (2.56s at 100Hz) — worst-case O(256 × 67) ≈ 17k ops/frame
            val count = minOf(stereoCapture.rmsHistoryCount, 256)
            val size = stereoCapture.rmsHistorySize
            val idxHead = stereoCapture.rmsHistoryIndex
            val srcBuffer = stereoCapture.fullRmsHistory

            val rawRms = FloatArray(count)
            var sum = 0f
            for (i in 0 until count) {
                val idx = (idxHead - count + i + size) % size
                val v = srcBuffer[idx]
                rawRms[i] = v
                sum += v
            }
            val mean = sum / count
            for (i in 0 until count) rawRms[i] -= mean

            // 100Hz → 10ms/sample. BPM 60–180 → lags 20–100 samples (333ms–1000ms).
            val msPerSample = 10.0
            val minLag = 20  // 333ms / 10ms
            val maxLag = minOf(100, count / 2)

            if (minLag < maxLag) {
                var bestLag = -1
                var bestCorr = -1.0
                // Only allocate for Mode A (parabolic) — Mode B and no-second-pass don't read it
                val corrValues = if (autocorrSecondPass && !autocorrSecondPassHq) DoubleArray(maxLag + 2) else null

                for (lag in minLag..maxLag) {
                    var corr = 0.0
                    for (i in 0 until count - lag) corr += rawRms[i] * rawRms[i + lag]
                    corrValues?.set(lag, corr)
                    if (corr > bestCorr) { bestCorr = corr; bestLag = lag }
                }

                if (bestLag > 0 && bestCorr > 0.0) {
                    var refinedLag = bestLag.toDouble()

                    if (autocorrSecondPass) {
                        if (!autocorrSecondPassHq) {
                            // Mode A: parabolic interpolation — ~3 extra ops, zero cost
                            if (bestLag > minLag && bestLag < maxLag) {
                                val cPrev = corrValues!![bestLag - 1]
                                val cBest = corrValues[bestLag]
                                val cNext = corrValues[bestLag + 1]
                                val denom = cPrev - 2.0 * cBest + cNext
                                if (denom < 0.0) refinedLag = bestLag + 0.5 * (cPrev - cNext) / denom
                            }
                        } else {
                            // Mode B: upsample ×4 in ±3-sample window around bestLag (Sabrina-disabled)
                            val windowStart = (bestLag - 3).coerceAtLeast(minLag)
                            val windowEnd   = (bestLag + 3).coerceAtMost(maxLag)
                            val upsampleFactor = 4
                            var hqBestLagF = bestLag.toDouble()
                            var hqBestCorr = -1.0
                            for (lagI in windowStart * upsampleFactor..windowEnd * upsampleFactor) {
                                val lagF = lagI.toDouble() / upsampleFactor
                                var corr = 0.0
                                for (i in 0 until count - windowEnd - 1) {
                                    // -1: ensures lo+1 stays in bounds (lo = srcI.toInt() ≤ windowEnd)
                                    // Linear interpolation lookup
                                    val srcI = lagF + i
                                    val lo = srcI.toInt().coerceIn(0, count - 1)
                                    val hi = (lo + 1).coerceIn(0, count - 1)
                                    val frac = srcI - lo
                                    val sample = rawRms[lo] * (1.0 - frac) + rawRms[hi] * frac
                                    corr += rawRms[i] * sample
                                }
                                if (corr > hqBestCorr) { hqBestCorr = corr; hqBestLagF = lagF }
                            }
                            refinedLag = hqBestLagF
                        }
                    }

                    val ibi = refinedLag * msPerSample
                    autocorrIbiMs = ibi
                    autocorrBpm = 60000.0 / ibi
                }
            }
        }

        // Only prefer autocorr when tracked grid has low or absent confidence
        val useAutocorr = autocorrBpm != null &&
            (trackedGridConfidence == null || trackedGridConfidence!! < 0.4)

        // Include stereo waveforms when AudioPlaybackCapture is active;
        // empty lists signal the Flutter side to fall back to fake-stereo FFT bands.
        val data = mapOf(
            "bass" to finalBass,
            "mid" to finalMid,
            "treble" to finalTreble,
            "overall" to overall,
            "isBeat" to isBeat,
            "beatScore" to finalBeatScore,
            "beatThreshold" to finalBeatThreshold,
            "beatConfidence" to finalBeatConfidence,
            "beatSource" to finalBeatSource,
            "beatBpm"   to if (useAutocorr) autocorrBpm else trackedBeatBpm,
            "beatIbiMs" to if (useAutocorr) autocorrIbiMs else trackedBeatIbiMs,
            "beatPhase" to trackedBeatPhase,
            "nextBeatMs" to trackedNextBeatMs,
            "beatGridConfidence" to trackedGridConfidence,
            "autocorrBpm" to autocorrBpm,
            "bands" to finalBands.toList(),
            "waveform" to pendingWaveform,
            "waveformL" to stereoCapture.waveformL, // real L PCM or empty
            "waveformR" to stereoCapture.waveformR, // real R PCM or empty
            "beatAlgos"  to beats.toList(),
            "algoLevels" to algoLevels.toList(),
            "algoSignals" to algoSignals.toList(),
            "algoBaselines" to algoBaselines.toList(),
            "algoThresholds" to algoThresholds.toList(),
            "winningAlgoId" to winningAlgoId,
            "debugAudioSessionId" to currentAudioSessionId,
            "debugPcmActive" to stereoCapture.isActive,
            "debugPcmFresh" to pcmFresh,
            "debugPcmAnalysisFrames" to stereoCapture.analysisFrames,
            "debugPcmAgeMs" to pcmAgeMs,
        )

        val sink = eventSink ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            sink.success(data)
        } else {
            mainHandler.post { eventSink?.success(data) }
        }
    }
}
