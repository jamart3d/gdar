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
 */
class VisualizerPlugin : MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "VisualizerPlugin"
        private const val METHOD_CHANNEL = "shakedown/visualizer"
        private const val EVENT_CHANNEL = "shakedown/visualizer_events"

        private const val BASS_MAX_FREQ = 250.0
        private const val MID_MAX_FREQ = 4000.0
        private const val CAPTURE_RATE_MS = 16 // ~60 FPS

        // Smoothing: 60% old value, 40% new — fixed, not user-configurable
        private const val SMOOTHING = 0.6

        private const val PEAK_FLOOR = 0.01
    }

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRunning = false

    // Smoothed values carried between frames
    private var smoothBass = 0.0
    private var smoothMid = 0.0
    private var smoothTreble = 0.0

    // Rolling peaks for normalization
    private var peakBass = PEAK_FLOOR
    private var peakMid = PEAK_FLOOR
    private var peakTreble = PEAK_FLOOR

    // Tuning knobs — updated live from Flutter settings
    private var peakDecay = 0.998
    private var bassBoost = 1.0
    private var reactivityStrength = 1.0

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
                    CAPTURE_RATE_MS,
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
        val frequencyResolution = samplingRate / 2.0 / numFrequencies

        var bassSum = 0.0
        var midSum = 0.0
        var trebleSum = 0.0
        var bassCount = 0
        var midCount = 0
        var trebleCount = 0

        for (i in 1 until numFrequencies) {
            val frequency = i * frequencyResolution
            val real = fft[i * 2].toInt()
            val imaginary = fft[i * 2 + 1].toInt()
            val magnitudeSquared = (real * real + imaginary * imaginary).toDouble()

            when {
                frequency < BASS_MAX_FREQ -> { bassSum += magnitudeSquared; bassCount++ }
                frequency < MID_MAX_FREQ  -> { midSum += magnitudeSquared; midCount++ }
                else                      -> { trebleSum += magnitudeSquared; trebleCount++ }
            }
        }

        // RMS per band
        var rawBass = if (bassCount > 0) sqrt(bassSum / bassCount) / 128.0 else 0.0
        val rawMid = if (midCount > 0) sqrt(midSum / midCount) / 128.0 else 0.0
        val rawTreble = if (trebleCount > 0) sqrt(trebleSum / trebleCount) / 128.0 else 0.0

        // Apply bass boost before normalization
        rawBass = (rawBass * bassBoost).coerceIn(0.0, 2.0)

        // Update rolling peaks using the user-controlled decay rate
        peakBass = max(peakBass * peakDecay, max(rawBass, PEAK_FLOOR))
        peakMid = max(peakMid * peakDecay, max(rawMid, PEAK_FLOOR))
        peakTreble = max(peakTreble * peakDecay, max(rawTreble, PEAK_FLOOR))

        // Normalize against peak
        val normalizedBass = (rawBass / peakBass).coerceIn(0.0, 1.0)
        val normalizedMid = (rawMid / peakMid).coerceIn(0.0, 1.0)
        val normalizedTreble = (rawTreble / peakTreble).coerceIn(0.0, 1.0)

        // Exponential smoothing to kill jitter
        smoothBass = smoothBass * SMOOTHING + normalizedBass * (1.0 - SMOOTHING)
        smoothMid = smoothMid * SMOOTHING + normalizedMid * (1.0 - SMOOTHING)
        smoothTreble = smoothTreble * SMOOTHING + normalizedTreble * (1.0 - SMOOTHING)

        // Apply overall reactivity strength scaling
        val finalBass = (smoothBass * reactivityStrength).coerceIn(0.0, 1.0)
        val finalMid = (smoothMid * reactivityStrength).coerceIn(0.0, 1.0)
        val finalTreble = (smoothTreble * reactivityStrength).coerceIn(0.0, 1.0)
        val overall = (finalBass + finalMid + finalTreble) / 3.0

        val data = mapOf(
            "bass" to finalBass,
            "mid" to finalMid,
            "treble" to finalTreble,
            "overall" to overall
        )

        eventSink?.success(data)
    }
}