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
  final Directory _cacheDir;

  int _cachedTrackCount = 0;

  /// Returns the current number of cached audio files (non-blocking).
  int get cachedTrackCount => _cachedTrackCount;

  AudioCacheService({Directory? cacheDir})
      : _cacheDir = cacheDir ?? Directory.systemTemp {
    refreshCacheCount();
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
      // Create a stable cache key based on the URL
      final key = sha256.convert(utf8.encode(uri.toString())).toString();
      return LockCachingAudioSource(
        uri,
        tag: tag,
        cacheFile: File('${_cacheDir.path}/$key'),
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
      if (!await _cacheDir.exists()) {
        _updateCount(0);
        return;
      }

      int count = 0;
      await for (final entity in _cacheDir.list()) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.length == 64) {
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
      if (await _cacheDir.exists()) {
        final List<FileSystemEntity> files = _cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            final name = file.uri.pathSegments.last;
            // Identify our cache files (SHA-256 hash length is 64)
            if (name.length == 64 && double.tryParse(name) == null) {
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
      if (!await _cacheDir.exists()) return;

      final List<FileSystemEntity> files = _cacheDir.listSync();
      final List<File> audioFiles = [];

      for (final entity in files) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.length == 64) {
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
