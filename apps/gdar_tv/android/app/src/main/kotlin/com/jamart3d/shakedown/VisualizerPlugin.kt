package com.jamart3d.shakedown

import android.media.audiofx.Visualizer
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

        // Number of beat-detection algorithms run in parallel (for beat_debug mode).
        private const val NUM_BEAT_ALGOS = 6

        // Oscilloscope: number of PCM points sent to Flutter per frame.
        private const val WAVEFORM_POINTS = 256

        // Noise gate: energy below this is treated as silence (0.01 = 1% volume)
        private const val SILENCE_THRESHOLD = 0.01
    }

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRunning = false

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
            "start" -> { start(); result.success(true) }
            "stop" -> { stop(); result.success(true) }
            "release" -> { release(); result.success(true) }
            "updateConfig" -> {
                // Receive tuning knobs from Flutter settings in real time
                peakDecay = call.argument<Double>("peakDecay") ?: peakDecay
                bassBoost = call.argument<Double>("bassBoost") ?: bassBoost
                reactivityStrength = call.argument<Double>("reactivityStrength") ?: reactivityStrength
                beatSensitivity = call.argument<Double>("beatSensitivity") ?: beatSensitivity
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
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
            result.add(((waveform[idx].toInt() and 0xFF) - 128) / 128.0f)
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

        val nowMs = System.currentTimeMillis()

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
        val pcmFresh =
            stereoCapture.lastAnalysisMs > 0L &&
            (nowMs - stereoCapture.lastAnalysisMs) <= 250L
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

        val preferPcmBeat = pcmWarmupReady && pcmHasSignal
        val finalBeatScore = if (preferPcmBeat) pcmScore else hybridScore
        val finalBeatThreshold = if (preferPcmBeat) pcmThreshold else beatThreshold
        val finalBeatConfidence = if (preferPcmBeat) pcmConfidence else hybridConfidence
        val finalBeatSource = if (preferPcmBeat) "PCM" else "VIS"
        val isBeat = if (preferPcmBeat) pcmIsBeat else hybridIsBeat

        val beats = BooleanArray(NUM_BEAT_ALGOS)
        // 0 BASS   – pre-boost bass vs 20-frame mean
        beats[0] = normBeat(sig0, bassHistory,   adaptiveMultiplier, 0)
        // 1 MID    – normalizedMid vs 20-frame mean
        beats[1] = normBeat(sig1, midHistory,    adaptiveMultiplier, 1)
        // 2 BROAD  – (bass+mid)/2 vs 20-frame mean
        beats[2] = normBeat(sig3, broadHistory,  adaptiveMultiplier, 2)
        // 3 ALL    – all-band onset vs 20-frame mean
        beats[3] = normBeat(sig4, allHistory,    adaptiveMultiplier, 3)
        // 4 EMA    – normalizedMid vs its own EMA background (classic onset)
        beats[4] = midEmaWarmup.size >= 10 &&
                   midEmaVal > SILENCE_THRESHOLD &&
                   sig1 > midEmaVal * (1.0 + (1.0 - beatSensitivity) * 0.5) &&
                   (nowMs - lastBeatMs[4]) > MIN_BEAT_GAP_MS
        if (beats[4]) lastBeatMs[4] = nowMs
        // 5 TREB   – normalizedTreble vs 20-frame mean
        beats[5] = normBeat(sig2, trebleHistory, adaptiveMultiplier, 5)
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

        val emaThresholdRatio = 1.0 + (1.0 - beatSensitivity) * 0.5
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
            scoreVsMean(sig0, bassHistory).coerceIn(0.0, 3.0),                               // 0 BASS
            scoreVsMean(sig1, midHistory).coerceIn(0.0, 3.0),                                // 1 MID
            scoreVsMean(sig3, broadHistory).coerceIn(0.0, 3.0),                              // 2 BROAD
            scoreVsMean(sig4, allHistory).coerceIn(0.0, 3.0),                                // 3 ALL
            scoreVsEma(sig1, midEmaVal, midEmaWarmup.size >= 10).coerceIn(0.0, 3.0),         // 4 EMA
            scoreVsMean(sig2, trebleHistory).coerceIn(0.0, 3.0),                             // 5 TREB
        )
        val winningAlgoId = algoLevels.indices.maxByOrNull { algoLevels[it] }
            ?.takeIf { algoLevels[it] > 0.0 }
            ?: -1

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
            "bands" to finalBands.toList(),
            "waveform" to pendingWaveform,
            "waveformL" to stereoCapture.waveformL, // real L PCM or empty
            "waveformR" to stereoCapture.waveformR, // real R PCM or empty
            "beatAlgos"  to beats.toList(),
            "algoLevels" to algoLevels.toList(),
            "algoSignals" to algoSignals.toList(),
            "algoBaselines" to algoBaselines.toList(),
            "algoThresholds" to algoThresholds.toList(),
            "winningAlgoId" to winningAlgoId
        )

        eventSink?.success(data)
    }
}
