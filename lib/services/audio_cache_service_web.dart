import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/models/source.dart';

class AudioCacheService with ChangeNotifier {
  int get cachedTrackCount => 0;

  Future<void> init() async {}

  AudioSource createAudioSource({
    required Uri uri,
    required MediaItem tag,
    required bool useCache,
  }) {
    return AudioSource.uri(
      uri,
      tag: tag,
      headers: {'User-Agent': 'GDAR/1.0.0 (shakedown_app@googlegroups.com)'},
    );
  }

  void monitorCache(bool enabled) {}

  Future<void> refreshCacheCount() async {}

  Future<void> clearAudioCache() async {}

  Future<void> performCacheCleanup({int maxFiles = 20}) async {}

  Future<void> preloadSource(Source source, {int startIndex = 0}) async {}

  Future<Uri?> getAlbumArtUri() async {
    return null;
  }
}
