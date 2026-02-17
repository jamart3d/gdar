package com.jamart3d.shakedown

import android.media.audiofx.Visualizer
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt

/**
 * Android Visualizer API plugin for screensaver visualizer.
 * 
 * Performs FFT analysis on audio output and sends frequency band energy
 * data to Flutter via EventChannel.
 */
class VisualizerPlugin : MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "VisualizerPlugin"
        private const val METHOD_CHANNEL = "shakedown/visualizer"
        private const val EVENT_CHANNEL = "shakedown/visualizer_events"
        
        // FFT frequency band ranges (Hz)
        private const val BASS_MAX_FREQ = 250.0
        private const val MID_MAX_FREQ = 4000.0
        // Treble is everything above MID_MAX_FREQ
        
        // Capture rate in milliseconds
        private const val CAPTURE_RATE_MS = 16 // ~60 FPS
    }
    
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRunning = false
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(isVisualizerAvailable())
            }
            "initialize" -> {
                val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                result.success(initialize(audioSessionId))
            }
            "start" -> {
                start()
                result.success(true)
            }
            "stop" -> {
                stop()
                result.success(true)
            }
            "release" -> {
                release()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
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
            // Try to create a temporary visualizer to check availability
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
            // Release any existing visualizer
            release()
            
            // Create new visualizer
            visualizer = Visualizer(audioSessionId).apply {
                // Set capture size to get FFT data
                // Must be a power of 2, 512 is a good balance
                captureSize = Visualizer.getCaptureSizeRange()[1]
                
                // Set data capture listener
                setDataCaptureListener(
                    object : Visualizer.OnDataCaptureListener {
                        override fun onWaveFormDataCapture(
                            visualizer: Visualizer?,
                            waveform: ByteArray?,
                            samplingRate: Int
                        ) {
                            // Not used, we only need FFT
                        }
                        
                        override fun onFftDataCapture(
                            visualizer: Visualizer?,
                            fft: ByteArray?,
                            samplingRate: Int
                        ) {
                            fft?.let { processFftData(it, samplingRate) }
                        }
                    },
                    CAPTURE_RATE_MS,
                    false, // waveform
                    true   // fft
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
    
    /**
     * Process FFT data and extract frequency band energies.
     * 
     * FFT data format from Android Visualizer:
     * - Index 0: DC component (ignored)
     * - Index 1: First frequency magnitude
     * - Indices 2-n: Alternating real and imaginary components
     */
    private fun processFftData(fft: ByteArray, samplingRate: Int) {
        if (eventSink == null) return
        
        val numFrequencies = fft.size / 2
        val frequencyResolution = samplingRate / 2.0 / numFrequencies
        
        var bassEnergy = 0.0
        var midEnergy = 0.0
        var trebleEnergy = 0.0
        var bassCount = 0
        var midCount = 0
        var trebleCount = 0
        
        // Process FFT bins
        for (i in 1 until numFrequencies) {
            val frequency = i * frequencyResolution
            
            // Get magnitude from real and imaginary components
            val real = fft[i * 2].toInt()
            val imaginary = fft[i * 2 + 1].toInt()
            val magnitude = sqrt((real * real + imaginary * imaginary).toDouble())
            
            // Accumulate energy in appropriate frequency band
            when {
                frequency < BASS_MAX_FREQ -> {
                    bassEnergy += magnitude
                    bassCount++
                }
                frequency < MID_MAX_FREQ -> {
                    midEnergy += magnitude
                    midCount++
                }
                else -> {
                    trebleEnergy += magnitude
                    trebleCount++
                }
            }
        }
        
        // Normalize energies (0.0-1.0 range)
        val bass = if (bassCount > 0) (bassEnergy / bassCount / 128.0).coerceIn(0.0, 1.0) else 0.0
        val mid = if (midCount > 0) (midEnergy / midCount / 128.0).coerceIn(0.0, 1.0) else 0.0
        val treble = if (trebleCount > 0) (trebleEnergy / trebleCount / 128.0).coerceIn(0.0, 1.0) else 0.0
        val overall = (bass + mid + treble) / 3.0
        
        // Send to Flutter
        val data = mapOf(
            "bass" to bass,
            "mid" to mid,
            "treble" to treble,
            "overall" to overall
        )
        
        eventSink?.success(data)
    }
}
