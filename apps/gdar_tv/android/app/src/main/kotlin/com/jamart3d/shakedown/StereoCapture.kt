package com.jamart3d.shakedown

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioPlaybackCaptureConfiguration
import android.media.projection.MediaProjection
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * Captures stereo PCM from the app's own audio playback via AudioPlaybackCapture (API 29+).
 *
 * Runs a background thread that continuously reads interleaved stereo PCM from an
 * AudioRecord wired to AudioPlaybackCaptureConfiguration.  On each read, it
 * downsamples L and R to [WAVEFORM_POINTS] points and exposes them as volatile
 * fields so VisualizerPlugin can include them in the event-channel payload without
 * waiting or blocking.
 *
 * Requires a MediaProjection obtained via MediaProjectionManager in MainActivity.
 * Falls back gracefully: if start() returns false, waveformL/R stay empty and
 * VisualizerPlugin omits them from the payload — the Flutter side then falls back
 * to the fake-stereo FFT-band split.
 */
class StereoCapture {

    companion object {
        private const val TAG = "StereoCapture"
        private const val SAMPLE_RATE = 44100
        const val WAVEFORM_POINTS = 256
    }

    /** Latest downsampled left-channel PCM, range -1.0..1.0. Empty until capture starts. */
    @Volatile var waveformL: List<Float> = emptyList()
        private set

    /** Latest downsampled right-channel PCM, range -1.0..1.0. Empty until capture starts. */
    @Volatile var waveformR: List<Float> = emptyList()
        private set

    /** True when AudioRecord is running and producing data. */
    @Volatile var isActive: Boolean = false
        private set

    private var audioRecord: AudioRecord? = null
    private var captureThread: Thread? = null
    @Volatile private var isRunning = false

    /**
     * Start stereo capture using [projection].
     * Returns true on success; false if the device is below API 29, AudioRecord failed to
     * initialise, or permission was denied — callers should treat false as graceful fallback.
     */
    fun start(projection: MediaProjection): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            Log.d(TAG, "AudioPlaybackCapture requires API 29+ — skipping stereo capture")
            return false
        }
        stop() // release any previous session

        return try {
            val channelConfig = AudioFormat.CHANNEL_IN_STEREO
            val encoding = AudioFormat.ENCODING_PCM_16BIT
            val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, channelConfig, encoding)
            // Buffer large enough for ~100 ms of stereo 16-bit PCM
            val bufferSize = maxOf(minBuf * 4, WAVEFORM_POINTS * 4)

            @Suppress("NewApi")
            val captureConfig = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .build()

            val record = AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(captureConfig)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(encoding)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(channelConfig)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .build()

            if (record.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord failed to initialise for stereo capture")
                record.release()
                return false
            }

            audioRecord = record
            record.startRecording()
            isRunning = true
            isActive = true

            val shortBuf = ShortArray(bufferSize / 2) // buffer in shorts (2 bytes each)
            captureThread = Thread {
                while (isRunning) {
                    val read = record.read(shortBuf, 0, shortBuf.size)
                    if (read > 1) processBuffer(shortBuf, read)
                }
            }.also {
                it.isDaemon = true
                it.name = "StereoCapture"
                it.start()
            }

            Log.d(TAG, "StereoCapture started (bufSize=$bufferSize)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "StereoCapture start failed: ${e.message}")
            false
        }
    }

    /**
     * Downsample one read-buffer into [WAVEFORM_POINTS] L and R points.
     * [buffer] is interleaved stereo shorts: index 0,2,4… = L; 1,3,5… = R.
     * [count] is the number of valid shorts in [buffer].
     */
    private fun processBuffer(buffer: ShortArray, count: Int) {
        val frameCount = count / 2 // stereo frames
        if (frameCount == 0) return
        val step = maxOf(1, frameCount / WAVEFORM_POINTS)

        val l = ArrayList<Float>(WAVEFORM_POINTS)
        val r = ArrayList<Float>(WAVEFORM_POINTS)

        var frameIdx = 0
        while (frameIdx < frameCount && l.size < WAVEFORM_POINTS) {
            val si = frameIdx * 2 // sample index for this frame's L channel
            if (si + 1 < count) {
                l.add(buffer[si].toFloat() / 32768f)
                r.add(buffer[si + 1].toFloat() / 32768f)
            }
            frameIdx += step
        }

        waveformL = l
        waveformR = r
    }

    /** Stop capture and release AudioRecord. Safe to call multiple times. */
    fun stop() {
        isRunning = false
        isActive = false
        captureThread?.interrupt()
        captureThread?.join(500)
        captureThread = null
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping AudioRecord: ${e.message}")
        }
        audioRecord = null
        waveformL = emptyList()
        waveformR = emptyList()
    }
}
