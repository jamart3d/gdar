package com.jamart3d.shakedown

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jamart3d.shakedown/ui_scale"
    private val TAG = "MainActivity"
    
    private var methodChannel: MethodChannel? = null

    // This is the crucial part.
    // It connects the AudioService plugin to your app's FlutterEngine.
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up MethodChannel for ADB UI scale testing
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        Log.d(TAG, "MethodChannel configured: $CHANNEL")
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
                methodChannel?.invokeMethod("setUiScale", enabled)
            }
        }
    }
}