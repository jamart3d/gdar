package com.jamart3d.shakedown

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class MediaProjectionForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "enhanced_audio_capture"
        private const val NOTIFICATION_ID = 4107
        private const val ACTION_START =
            "com.jamart3d.shakedown.action.START_ENHANCED_CAPTURE"
        private val mainHandler = Handler(Looper.getMainLooper())
        private val pendingReadyCallbacks = mutableListOf<() -> Unit>()
        @Volatile
        private var isForegroundReady = false

        fun start(context: Context) {
            val intent = Intent(context, MediaProjectionForegroundService::class.java)
                .setAction(ACTION_START)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, MediaProjectionForegroundService::class.java))
        }

        fun runWhenReady(action: () -> Unit) {
            val runNow = synchronized(pendingReadyCallbacks) {
                if (isForegroundReady) {
                    true
                } else {
                    pendingReadyCallbacks.add(action)
                    false
                }
            }
            if (runNow) {
                mainHandler.post(action)
            }
        }

        private fun markForegroundReady() {
            val callbacks = synchronized(pendingReadyCallbacks) {
                isForegroundReady = true
                pendingReadyCallbacks.toList().also { pendingReadyCallbacks.clear() }
            }
            callbacks.forEach { callback -> mainHandler.post(callback) }
        }

        private fun markStopped() {
            synchronized(pendingReadyCallbacks) {
                isForegroundReady = false
                pendingReadyCallbacks.clear()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startCaptureForeground()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        markStopped()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun startCaptureForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Enhanced Audio Capture",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Stereo system audio capture for the screensaver"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.app_name))
            .setContentText("Enhanced audio capture is active")
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        markForegroundReady()
    }
}
