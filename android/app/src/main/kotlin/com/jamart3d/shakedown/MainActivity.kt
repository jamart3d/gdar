package com.jamart3d.shakedown

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jamart3d.shakedown/device"
    private val UI_SCALE_CHANNEL = "com.jamart3d.shakedown/ui_scale"
    private val TAG = "MainActivity"
    
    private var deviceChannel: MethodChannel? = null
    private var uiScaleChannel: MethodChannel? = null

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
        
        // Register Visualizer plugin
        val visualizerPlugin = VisualizerPlugin()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shakedown/visualizer")
            .setMethodCallHandler(visualizerPlugin)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "shakedown/visualizer_events")
            .setStreamHandler(visualizerPlugin)
        
        Log.d(TAG, "MethodChannels configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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