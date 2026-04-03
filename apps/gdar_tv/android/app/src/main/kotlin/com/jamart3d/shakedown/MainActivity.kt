package com.jamart3d.shakedown

import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jamart3d.shakedown/device"
    private val UI_SCALE_CHANNEL = "com.jamart3d.shakedown/ui_scale"
    private val STEREO_CHANNEL = "shakedown/stereo"
    private val TAG = "MainActivity"

    private companion object {
        const val REQUEST_CAPTURE = 1001
    }

    private var deviceChannel: MethodChannel? = null
    private var uiScaleChannel: MethodChannel? = null
    private var stereoMethodChannel: MethodChannel? = null

    // Shared with VisualizerPlugin so it can include L/R waveforms in the FFT event payload.
    private val stereoCapture = StereoCapture()
    // Pending Flutter result waiting for activity-result callback.
    private var pendingStereoResult: MethodChannel.Result? = null

    private fun deviceSummary(): String {
        return "sdk=${Build.VERSION.SDK_INT} " +
            "release=${Build.VERSION.RELEASE} " +
            "brand=${Build.BRAND} " +
            "manufacturer=${Build.MANUFACTURER} " +
            "model=${Build.MODEL} " +
            "device=${Build.DEVICE}"
    }

    private fun resetStereoCaptureSession() {
        stereoCapture.stop()
        MediaProjectionForegroundService.stop(this)
    }

    private fun failStereoRequest(
        result: MethodChannel.Result?,
        reason: String,
        error: Throwable? = null,
    ) {
        pendingStereoResult = null
        resetStereoCaptureSession()
        if (error != null) {
            Log.e(TAG, "$reason (${deviceSummary()})", error)
        } else {
            Log.w(TAG, "$reason (${deviceSummary()})")
        }
        result?.success(false)
    }

    private fun launchStereoConsentDialog(
        result: MethodChannel.Result,
        reason: String,
    ) {
        try {
            val mgr = getSystemService(MEDIA_PROJECTION_SERVICE)
                as? MediaProjectionManager
            if (mgr == null) {
                failStereoRequest(result, "MediaProjectionManager unavailable")
                return
            }
            Log.i(TAG, "Launching MediaProjection consent dialog ($reason)")
            startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_CAPTURE)
        } catch (t: Throwable) {
            failStereoRequest(result, "Failed to launch consent dialog", t)
        }
    }

    private fun handleStereoCaptureResult(resultCode: Int, data: Intent?) {
        Log.i(
            TAG,
            "Stereo capture activity result received " +
                "(resultCode=$resultCode, hasData=${data != null}, ${deviceSummary()})",
        )
        val result = pendingStereoResult
        pendingStereoResult = null
        if (resultCode == Activity.RESULT_OK && data != null) {
            try {
                stereoCapture.stop()

                // Obtain the MediaProjection token immediately inside the activity-result
                // callback. Android 14 invalidates the consent intent once this callback
                // returns, so deferring getMediaProjection() can crash.
                val mgr = getSystemService(MEDIA_PROJECTION_SERVICE)
                    as MediaProjectionManager
                val projection = mgr.getMediaProjection(resultCode, data)
                if (projection == null) {
                    resetStereoCaptureSession()
                    result?.success(false)
                    Log.w(TAG, "getMediaProjection returned null")
                    return
                }

                // Do not restart the foreground service here.
                // On API 34+ it was started before the consent dialog and should still
                // be running. Restarting it can race against the live capture token.
                // On older builds, forcing a mediaProjection service type on some TV
                // devices has caused permission failures even though plain
                // AudioPlaybackCapture may still work.
                try {
                    val ok = stereoCapture.start(projection)
                    if (!ok) {
                        resetStereoCaptureSession()
                        Log.w(
                            TAG,
                            "Stereo capture start returned false (${deviceSummary()})",
                        )
                    }
                    result?.success(ok)
                    Log.d(TAG, "Stereo capture started: $ok")
                } catch (t: Throwable) {
                    failStereoRequest(result, "Failed to start stereo capture", t)
                }
            } catch (t: Throwable) {
                failStereoRequest(result, "Failed to resolve stereo capture result", t)
            }
        } else {
            resetStereoCaptureSession()
            result?.success(false)
            Log.d(TAG, "Stereo capture permission denied")
        }
    }

    // This is the crucial part.
    // It connects the AudioService plugin to your app's FlutterEngine.
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        deviceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        deviceChannel?.setMethodCallHandler { call, result ->
            if (call.method == "isTv") {
                val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                val isTv =
                    uiModeManager.currentModeType ==
                        Configuration.UI_MODE_TYPE_TELEVISION
                result.success(isTv)
            } else {
                result.notImplemented()
            }
        }

        uiScaleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UI_SCALE_CHANNEL,
        )

        val visualizerPlugin = VisualizerPlugin(stereoCapture)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shakedown/visualizer")
            .setMethodCallHandler(visualizerPlugin)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "shakedown/visualizer_events",
        ).setStreamHandler(visualizerPlugin)

        stereoMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STEREO_CHANNEL,
        )
        stereoMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCapture" -> {
                    Log.i(
                        TAG,
                        "Stereo capture request received " +
                            "(active=${stereoCapture.isActive}, " +
                            "pending=${pendingStereoResult != null}, " +
                            "${deviceSummary()})",
                    )
                    if (stereoCapture.isActive) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    if (pendingStereoResult != null) {
                        Log.w(TAG, "Stereo capture request already pending")
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    pendingStereoResult = result
                    stereoCapture.stop()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val fgStartIssued =
                            MediaProjectionForegroundService.start(this)
                        if (fgStartIssued) {
                            MediaProjectionForegroundService.runWhenReady(
                                onReady = {
                                    launchStereoConsentDialog(
                                        result,
                                        "API 34+, foreground service ready",
                                    )
                                },
                                onUnavailable = {
                                    Log.w(
                                        TAG,
                                        "FG service unavailable; attempting direct consent dialog",
                                    )
                                    launchStereoConsentDialog(
                                        result,
                                        "API 34+, foreground service unavailable",
                                    )
                                },
                            )
                        } else {
                            Log.w(
                                TAG,
                                "FG service start failed synchronously; " +
                                    "attempting direct consent dialog",
                            )
                            launchStereoConsentDialog(
                                result,
                                "API 34+, foreground service start failed",
                            )
                        }
                    } else {
                        resetStereoCaptureSession()
                        launchStereoConsentDialog(result, "pre-API 34")
                    }
                }

                "stopCapture" -> {
                    resetStereoCaptureSession()
                    result.success(true)
                }

                "getCaptureStatus" -> {
                    result.success(
                        mapOf(
                            "active" to stereoCapture.isActive,
                            "pending" to (pendingStereoResult != null),
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannels configured")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CAPTURE) {
            handleStereoCaptureResult(resultCode, data)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.i(
            TAG,
            "onResume (pendingStereo=${pendingStereoResult != null}, " +
                "active=${stereoCapture.isActive})",
        )
    }

    override fun onPause() {
        Log.i(
            TAG,
            "onPause (pendingStereo=${pendingStereoResult != null}, " +
                "active=${stereoCapture.isActive})",
        )
        super.onPause()
    }

    override fun onStop() {
        Log.i(
            TAG,
            "onStop (pendingStereo=${pendingStereoResult != null}, " +
                "active=${stereoCapture.isActive})",
        )
        super.onStop()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        handleDeepLink(intent)
    }

    override fun onDestroy() {
        resetStereoCaptureSession()
        super.onDestroy()
    }

    private fun handleDeepLink(intent: Intent?) {
        val data: Uri? = intent?.data
        if (data != null && data.scheme == "shakedown") {
            Log.d(TAG, "Deep link received: $data")
            if (data.host == "ui-scale") {
                val enabled = data.getQueryParameter("enabled")?.toBoolean() ?: false
                Log.d(TAG, "UI scale deep link: enabled=$enabled")
                uiScaleChannel?.invokeMethod("setUiScale", enabled)
            }
        }
    }
}
