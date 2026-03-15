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
 *   bassBoost          (1.0–3.0)     Multiplier applied to bass energy before smoothing.
 *   reactivityStrength (0.5–2.0)     Global scale applied to all bands before sending to Flutter.
 *   beatSensitivity    (0.0–1.0)     How sensitive the onset detector is. Higher = more beats.
 */
class VisualizerPlugin : MethodCallHandler, EventChannel.StreamHandler {
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

        // Beat detection: minimum gap between detected beats (ms)
        private const val MIN_BEAT_GAP_MS = 200L

        // Number of frames to average for onset detection
        private const val ONSET_HISTORY_SIZE = 8

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

    // Rolling peaks for normalization (3-band legacy)
    private var peakBass = PEAK_FLOOR
    private var peakMid = PEAK_FLOOR
    private var peakTreble = PEAK_FLOOR

    // Rolling peaks for 8-band normalization
    private val peakBands = DoubleArray(8) { PEAK_FLOOR }

    // Tuning knobs — updated live from Flutter settings
    private var peakDecay = 0.998
    private var bassBoost = 1.0
    private var reactivityStrength = 1.0
    private var beatSensitivity = 0.5

    // Onset detection state
    private val recentBassHistory = ArrayDeque<Double>(ONSET_HISTORY_SIZE)
    private var lastBeatTimeMs = 0L

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
                        ) { /* Not used */ }

                        override fun onFftDataCapture(
                            visualizer: Visualizer?, fft: ByteArray?, samplingRate: Int
                        ) {
                            fft?.let { processFftData(it, samplingRate) }
                        }
                    },
                    maxRate,
                    false,
                    true
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
            smoothBands.fill(0.0)
            peakBands.fill(PEAK_FLOOR)
            recentBassHistory.clear()
            lastBeatTimeMs = 0L

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
        var rawBass = if (bassCount > 0) sqrt(bassSum / bassCount) / 128.0 else 0.0
        val rawMid = if (midCount > 0) sqrt(midSum / midCount) / 128.0 else 0.0
        val rawTreble = if (trebleCount > 0) sqrt(trebleSum / trebleCount) / 128.0 else 0.0

        // Apply bass boost before normalization
        rawBass = (rawBass * bassBoost).coerceIn(0.0, 2.0)

        // Update rolling peaks using the user-controlled decay rate
        // If the signal is pure silence, we eventually reset peaks to PEAK_FLOOR
        // to prevent normalization artifacts when music starts again.
        if (rawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD) {
            peakBass = max(peakBass * peakDecay, PEAK_FLOOR)
            peakMid = max(peakMid * peakDecay, PEAK_FLOOR)
            peakTreble = max(peakTreble * peakDecay, PEAK_FLOOR)
        } else {
            peakBass = max(peakBass * peakDecay, max(rawBass, PEAK_FLOOR))
            peakMid = max(peakMid * peakDecay, max(rawMid, PEAK_FLOOR))
            peakTreble = max(peakTreble * peakDecay, max(rawTreble, PEAK_FLOOR))
        }

        // Normalize against peak, applying noise gate (hard floor)
        val normalizedBass = if (rawBass < SILENCE_THRESHOLD) 0.0 else (rawBass / peakBass).coerceIn(0.0, 1.0)
        val normalizedMid = if (rawMid < SILENCE_THRESHOLD) 0.0 else (rawMid / peakMid).coerceIn(0.0, 1.0)
        val normalizedTreble = if (rawTreble < SILENCE_THRESHOLD) 0.0 else (rawTreble / peakTreble).coerceIn(0.0, 1.0)

        // Exponential smoothing to kill jitter
        smoothBass = smoothBass * SMOOTHING + normalizedBass * (1.0 - SMOOTHING)
        smoothMid = smoothMid * SMOOTHING + normalizedMid * (1.0 - SMOOTHING)
        smoothTreble = smoothTreble * SMOOTHING + normalizedTreble * (1.0 - SMOOTHING)

        // Apply overall reactivity strength scaling
        val finalBass = (smoothBass * reactivityStrength).coerceIn(0.0, 1.0)
        val finalMid = (smoothMid * reactivityStrength).coerceIn(0.0, 1.0)
        val finalTreble = (smoothTreble * reactivityStrength).coerceIn(0.0, 1.0)
        val overall = (finalBass + finalMid + finalTreble) / 3.0

        // ── 8-band processing ───────────────────────────────────────────
        val isSilent = rawBass < SILENCE_THRESHOLD && rawMid < SILENCE_THRESHOLD && rawTreble < SILENCE_THRESHOLD
        val finalBands = DoubleArray(8)
        for (b in 0 until 8) {
            val rawBand = if (bandCounts[b] > 0) sqrt(bandSums[b] / bandCounts[b]) / 128.0 else 0.0
            // Mirror the 3-band silence gating: decay peaks during silence
            if (isSilent) {
                peakBands[b] = max(peakBands[b] * peakDecay, PEAK_FLOOR)
            } else {
                peakBands[b] = max(peakBands[b] * peakDecay, max(rawBand, PEAK_FLOOR))
            }
            val normalized = if (rawBand < SILENCE_THRESHOLD) 0.0 else (rawBand / peakBands[b]).coerceIn(0.0, 1.0)
            smoothBands[b] = smoothBands[b] * SMOOTHING + normalized * (1.0 - SMOOTHING)
            finalBands[b] = (smoothBands[b] * reactivityStrength).coerceIn(0.0, 1.0)
        }

        // ── Beat detection (onset detection on bass energy) ─────────────
        // Detect beat from pre-boost bass so visual gain does not alter trigger rate.
        val beatBass = if (bassBoost > 0.0) {
            (rawBass / bassBoost).coerceIn(0.0, 2.0)
        } else {
            rawBass
        }

        var isBeat = false
        if (recentBassHistory.size >= 3) {
            val avgBass = recentBassHistory.average()
            // threshold scales with sensitivity: 0.0 -> needs 3x avg, 1.0 -> needs 1x avg
            val threshold = 1.0 + (1.0 - beatSensitivity) * 2.0
            val nowMs = System.currentTimeMillis()
            if (beatBass > avgBass * threshold &&
                (nowMs - lastBeatTimeMs) > MIN_BEAT_GAP_MS
            ) {
                isBeat = true
                lastBeatTimeMs = nowMs
            }
        }

        recentBassHistory.addLast(beatBass)
        if (recentBassHistory.size > ONSET_HISTORY_SIZE) {
            recentBassHistory.removeFirst()
        }

        val data = mapOf(
            "bass" to finalBass,
            "mid" to finalMid,
            "treble" to finalTreble,
            "overall" to overall,
            "isBeat" to isBeat,
            "bands" to finalBands.toList()
        )

        eventSink?.success(data)
    }
}
