import 'dart:io' show Platform;
import 'package:shakedown/oil_slide/oil_slide_audio_reactor.dart';
import 'package:shakedown/oil_slide/position_audio_reactor.dart';
import 'package:shakedown/oil_slide/visualizer_audio_reactor.dart';

/// Factory for creating the appropriate audio reactor based on platform capabilities.
class OilSlideAudioReactorFactory {
  /// Create the appropriate audio reactor for the current platform.
  ///
  /// On Android with Visualizer API available, returns VisualizerAudioReactor.
  /// Otherwise, returns PositionAudioReactor as fallback.
  static Future<OilSlideAudioReactor> create({
    int? audioSessionId,
  }) async {
    // Check if we're on Android
    final isAndroid = Platform.isAndroid;

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
