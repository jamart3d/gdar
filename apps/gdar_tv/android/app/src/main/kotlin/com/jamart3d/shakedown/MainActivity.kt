package com.jamart3d.shakedown

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity: FlutterActivity() {
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

    private fun resetStereoCaptureSession() {
        stereoCapture.stop()
        MediaProjectionForegroundService.stop(this)
    }

    // This is the crucial part.
    // It connects the AudioService plugin to your app's FlutterEngine.
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up MethodChannel for Device info
        deviceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        deviceChannel?.setMethodCallHandler { call, result ->
            if (call.method == "isTv") {
                val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                val isTv = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                result.success(isTv)
            } else {
                result.notImplemented()
            }
        }

        // Set up MethodChannel for ADB UI scale testing
        uiScaleChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UI_SCALE_CHANNEL)
        
        // Register Visualizer plugin (shares stereoCapture to include L/R waveforms in payload)
        val visualizerPlugin = VisualizerPlugin(stereoCapture)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shakedown/visualizer")
            .setMethodCallHandler(visualizerPlugin)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "shakedown/visualizer_events")
            .setStreamHandler(visualizerPlugin)

        // Stereo capture control channel
        stereoMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STEREO_CHANNEL
        )
        stereoMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCapture" -> {
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
                    try {
                        // Clear any leftover projection/service state before
                        // launching a fresh system capture permission flow.
                        resetStereoCaptureSession()
                        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                        if (mgr == null) {
                            pendingStereoResult = null
                            Log.w(TAG, "MediaProjectionManager unavailable")
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_CAPTURE)
                    } catch (e: ActivityNotFoundException) {
                        pendingStereoResult = null
                        Log.w(TAG, "Stereo capture activity unavailable: ${e.message}")
                        result.success(false)
                    } catch (e: SecurityException) {
                        pendingStereoResult = null
                        Log.w(TAG, "Stereo capture permission launch blocked: ${e.message}")
                        result.success(false)
                    } catch (e: Exception) {
                        pendingStereoResult = null
                        Log.e(TAG, "Failed to launch stereo capture permission", e)
                        result.success(false)
                    }
                }
                "stopCapture" -> {
                    resetStereoCaptureSession()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannels configured")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CAPTURE) {
            val result = pendingStereoResult
            pendingStereoResult = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    resetStereoCaptureSession()
                    MediaProjectionForegroundService.start(this)
                } catch (e: Exception) {
                    resetStereoCaptureSession()
                    result?.success(false)
                    Log.e(TAG, "Failed to start capture foreground service", e)
                    return
                }
                MediaProjectionForegroundService.runWhenReady {
                    try {
                        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        val projection = mgr.getMediaProjection(resultCode, data)
                        if (projection != null) {
                            val ok = stereoCapture.start(projection)
                            if (!ok) {
                                resetStereoCaptureSession()
                            }
                            result?.success(ok)
                            Log.d(TAG, "Stereo capture started: $ok")
                        } else {
                            resetStereoCaptureSession()
                            result?.success(false)
                            Log.w(TAG, "getMediaProjection returned null")
                        }
                    } catch (e: SecurityException) {
                        resetStereoCaptureSession()
                        result?.success(false)
                        Log.w(TAG, "Stereo capture unavailable on this device: ${e.message}")
                    } catch (e: Exception) {
                        resetStereoCaptureSession()
                        result?.success(false)
                        Log.e(TAG, "Failed to start stereo capture", e)
                    }
                }
            } else {
                resetStereoCaptureSession()
                result?.success(false)
                Log.d(TAG, "Stereo capture permission denied")
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Opt into edge-to-edge for Android 15 (SDK 35) compliance.
        // Replaces the deprecated setNavigationBarColor / setStatusBarColor approach.
        // Flutter's MediaQuery.padding will handle content insets on the Dart side.
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
            
            // Handle ui-scale deep link: shakedown://ui-scale?enabled=true
            if (data.host == "ui-scale") {
                val enabled = data.getQueryParameter("enabled")?.toBoolean() ?: false
                Log.d(TAG, "UI scale deep link: enabled=$enabled")
                uiScaleChannel?.invokeMethod("setUiScale", enabled)
            }
        }
    }
}
