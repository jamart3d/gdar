import 'package:flutter/foundation.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/visualizer/position_audio_reactor.dart';
import 'package:shakedown/visualizer/visualizer_audio_reactor.dart';

/// Factory for creating the appropriate audio reactor based on platform capabilities.
class AudioReactorFactory {
  /// Create the appropriate audio reactor for the current platform.
  ///
  /// - On Web: Always returns PositionAudioReactor (fallback).
  /// - On Mobile (Phone): Always returns PositionAudioReactor (fallback).
  /// - On TV (Android): Returns VisualizerAudioReactor if available.
  static Future<AudioReactor> create({
    int? audioSessionId,
    bool isTv = false,
  }) async {
    // Web always uses position reactor
    if (kIsWeb) {
      return PositionAudioReactor();
    }

    // Strictly enforce TV-only for the real visualizer
    if (!isTv) {
      return PositionAudioReactor();
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

    // Fallback to position-based reactor
    return PositionAudioReactor();
  }
}
