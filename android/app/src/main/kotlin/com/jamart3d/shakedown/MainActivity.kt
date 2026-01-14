package com.jamart3d.shakedown

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity: FlutterActivity() {
    // This is the crucial part.
    // It connects the AudioService plugin to your app's FlutterEngine.
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }
}