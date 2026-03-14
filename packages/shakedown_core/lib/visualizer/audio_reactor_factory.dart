import 'package:flutter/foundation.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';

/// Factory for creating the appropriate audio reactor based on platform capabilities.
class AudioReactorFactory {
  /// Create the appropriate audio reactor for the current platform.
  ///
  /// - On Web: Always returns PositionAudioReactor (fallback).
  /// - On Mobile (Phone): Always returns PositionAudioReactor (fallback).
  /// - On TV (Android): Returns VisualizerAudioReactor if available.
  static Future<AudioReactor?> create({
    int? audioSessionId,
    bool isTv = false,
  }) async {
    // Strictly enforce TV-only for the real visualizer.
    // The screensaver and its audio reactivity are exclusively for the TV UI.
    if (!isTv || kIsWeb) {
      return null;
    }

    // Check if we're on Android (where Visualizer API exists)
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      // Try to use Android Visualizer API
      try {
        final isAvailable = await VisualizerAudioReactor.isAvailable();
        if (isAvailable) {
          return VisualizerAudioReactor(audioSessionId: audioSessionId);
        }
      } catch (e) {
        // Fall through to position reactor
      }
    }

    // If we're not on Android or it's not available, return null
    return null;
  }
}
