package com.jamart3d.shakedown

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class StereoCaptureTest {
    @Test
    fun getRmsSnapshot_returnsNullWhenHistoryIsEmpty() {
        val capture = StereoCapture()

        assertNull(capture.getRmsSnapshot())
    }

    @Test
    fun getRmsSnapshot_returnsSamplesOldestToNewestAfterWraparound() {
        val capture = StereoCapture()
        val history = capture.readPrivateFloatArray("fullRmsHistory")
        val size = StereoCapture.RMS_HISTORY_SIZE

        for (i in 0 until size) {
            history[i] = i.toFloat()
        }
        capture.writePrivateInt("rmsHistoryIndex", 3)
        capture.writePrivateInt("rmsHistoryCount", size)

        val snapshot = capture.getRmsSnapshot()

        assertEquals(size, snapshot?.count)
        val expected = FloatArray(size) { ((3 + it) % size).toFloat() }
        assertArrayEquals(expected, snapshot!!.samples, 0f)
    }

    private fun StereoCapture.readPrivateFloatArray(name: String): FloatArray {
        val field = StereoCapture::class.java.getDeclaredField(name)
        field.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        return field.get(this) as FloatArray
    }

    private fun StereoCapture.writePrivateInt(name: String, value: Int) {
        val field = StereoCapture::class.java.getDeclaredField(name)
        field.isAccessible = true
        field.setInt(this, value)
    }
}
