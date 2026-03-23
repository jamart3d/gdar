package com.jamart3d.shakedown

import android.app.Activity
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
                    pendingStereoResult = result
                    val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_CAPTURE)
                }
                "stopCapture" -> {
                    stereoCapture.stop()
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
                val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                val projection = mgr.getMediaProjection(resultCode, data)
                if (projection != null) {
                    val ok = stereoCapture.start(projection)
                    result?.success(ok)
                    Log.d(TAG, "Stereo capture started: $ok")
                } else {
                    result?.success(false)
                    Log.w(TAG, "getMediaProjection returned null")
                }
            } else {
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