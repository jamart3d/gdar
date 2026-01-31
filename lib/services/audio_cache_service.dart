import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/utils/logger.dart';

/// Service responsible for managing audio file caching using just_audio's
/// LockCachingAudioSource. Handles file counting, cleanup, and monitoring.
class AudioCacheService with ChangeNotifier {
  Timer? _cacheRefreshTimer;
  Directory? _cacheDir;

  int _cachedTrackCount = 0;

  /// Returns the current number of cached audio files (non-blocking).
  int get cachedTrackCount => _cachedTrackCount;

  /// Regex to identify cache files (SHA-256 hex hash)
  static final _cacheFileRegex = RegExp(r'^[a-f0-9]{64}$');

  AudioCacheService({Directory? cacheDir}) : _cacheDir = cacheDir {
    // Note: init() must be called to ensure directory is ready if no cacheDir provided
    if (_cacheDir != null) {
      refreshCacheCount();
    }
  }

  /// Initializes the dedicated cache directory.
  Future<void> init() async {
    if (_cacheDir == null) {
      final baseDir = Directory.systemTemp;
      _cacheDir = Directory('${baseDir.path}/shakedown_audio_cache');
      logger.i(
          'AudioCacheService: Using dedicated cache directory: ${_cacheDir!.path}');
    }

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    await refreshCacheCount();
  }

  @override
  void dispose() {
    _cacheRefreshTimer?.cancel();
    super.dispose();
  }

  /// Creates an AudioSource that is either cached or streaming based on [useCache].
  AudioSource createAudioSource({
    required Uri uri,
    required MediaItem tag,
    required bool useCache,
  }) {
    if (useCache) {
      // Ensure initialization
      if (_cacheDir == null) {
        // Fallback sync init for immediate source creation if init() wasn't called/awaited
        final baseDir = Directory.systemTemp;
        _cacheDir = Directory('${baseDir.path}/shakedown_audio_cache');
      }

      // Create a stable cache key based on the URL
      final key = sha256.convert(utf8.encode(uri.toString())).toString();
      return LockCachingAudioSource(
        uri,
        tag: tag,
        cacheFile: File('${_cacheDir!.path}/$key'),
      );
    } else {
      return AudioSource.uri(uri, tag: tag);
    }
  }

  /// Starts or stops the cache monitoring timer based on [isEnabled].
  void monitorCache(bool isEnabled) {
    if (isEnabled) {
      if (_cacheRefreshTimer == null || !_cacheRefreshTimer!.isActive) {
        logger.i('AudioCacheService: Starting cache refresh timer (5s)');
        // Initial refresh
        refreshCacheCount();
        _cacheRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          refreshCacheCount();
        });
      }
    } else {
      if (_cacheRefreshTimer != null) {
        logger.i('AudioCacheService: Stopping cache refresh timer');
        _cacheRefreshTimer?.cancel();
        _cacheRefreshTimer = null;
      }
    }
  }

  /// Asynchronously updates the cached track count.
  Future<void> refreshCacheCount() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) {
        _updateCount(0);
        return;
      }

      int count = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (_cacheFileRegex.hasMatch(name)) {
            count++;
          }
        }
      }

      _updateCount(count);
    } catch (e) {
      logger.w('Failed to refresh cache count: $e');
    }
  }

  void _updateCount(int count) {
    if (_cachedTrackCount != count) {
      _cachedTrackCount = count;
      notifyListeners();
    }
  }

  /// Clears all cached audio files.
  Future<void> clearAudioCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        final List<FileSystemEntity> files = _cacheDir!.listSync();
        for (final file in files) {
          if (file is File) {
            final name = file.uri.pathSegments.last;
            // Identify our cache files
            if (_cacheFileRegex.hasMatch(name)) {
              try {
                await file.delete();
              } catch (_) {}
            }
          }
        }
        logger.i('Cleared audio cache.');
        await refreshCacheCount();
      }
    } catch (e) {
      logger.w('Failed to clear audio cache: $e');
    }
  }

  /// Keep only the most recent [maxFiles] files in the cache.
  Future<void> performCacheCleanup({int maxFiles = 20}) async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) return;

      final List<FileSystemEntity> files = _cacheDir!.listSync();
      final List<File> audioFiles = [];

      for (final entity in files) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (_cacheFileRegex.hasMatch(name)) {
            audioFiles.add(entity);
          }
        }
      }

      if (audioFiles.length <= maxFiles) return;

      // Sort by Modification Time (Newest First)
      audioFiles.sort((a, b) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      });

      final filesToDelete = audioFiles.sublist(maxFiles);
      int deletedCount = 0;

      for (final file in filesToDelete) {
        try {
          await file.delete();
          deletedCount++;
        } catch (_) {
          // Ignore errors (file might be in use)
        }
      }

      if (deletedCount > 0) {
        logger.i(
            'Cache Cleanup: Removed $deletedCount old files. Remaining: $maxFiles');
        await refreshCacheCount();
      }
    } catch (e) {
      logger.w('Cache Cleanup Failed: $e');
    }
  }
}
