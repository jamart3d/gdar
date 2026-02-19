import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:http/http.dart' as http;
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';

/// Service responsible for managing audio file caching using just_audio's
/// LockCachingAudioSource. Handles file counting, cleanup, and monitoring.
class AudioCacheService with ChangeNotifier {
  Timer? _cacheRefreshTimer;
  Directory? _cacheDir;
  int _cachedTrackCount = 0;

  // Preloading State
  String? _activePreloadSourceId;
  final Set<String> _preloadingUrls = {};
  bool _isPreloadCancelled = false;
  http.Client? _httpClient;

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
    _cancelPreload();
    _httpClient?.close();
    super.dispose();
  }

  void _cancelPreload() {
    _isPreloadCancelled = true;
    _activePreloadSourceId = null;
    _preloadingUrls.clear();
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
      // ignore: experimental_member_use
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
  void monitorCache(bool enabled) {
    if (enabled && _cacheRefreshTimer == null) {
      logger.i('AudioCacheService: Starting cache refresh timer (5s)');
      refreshCacheCount();
      _cacheRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        refreshCacheCount();
      });
    } else if (!enabled && _cacheRefreshTimer != null) {
      logger.i('AudioCacheService: Stopping cache refresh timer');
      _cacheRefreshTimer?.cancel();
      _cacheRefreshTimer = null;
      _cancelPreload(); // Also cancel any active background downloads
    }
  }

  /// Asynchronously updates the cached track count.
  Future<void> refreshCacheCount() async {
    try {
      final dir = _cacheDir;
      if (dir == null || !await dir.exists()) {
        _updateCount(0);
        return;
      }

      int count = 0;
      // Use a try-catch around list() to handle case where dir is deleted during iteration
      try {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = entity.uri.pathSegments.last;
            if (_cacheFileRegex.hasMatch(name)) {
              count++;
            }
          }
        }
      } on FileSystemException catch (e) {
        // Directory might have been deleted during iteration (happens in tests)
        logger
            .d('refreshCacheCount: Directory disappeared during iteration: $e');
        if (await dir.exists()) {
          rethrow; // If it still exists, something else is wrong
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
      if (_cacheDir == null || !await _cacheDir!.exists()) return;

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

  /// Gracefully pre-loads all tracks for a given [source] in the background.
  Future<void> preloadSource(Source source, {int startIndex = 0}) async {
    // 1. Check if we are already preloading this specific source
    if (_activePreloadSourceId == source.id) {
      return;
    }

    // 2. Cancel any existing preload
    _cancelPreload();
    _isPreloadCancelled = false;
    _activePreloadSourceId = source.id;
    _httpClient ??= http.Client();

    logger.i('Smart Pre-Load: Starting for source ${source.id}...');

    // 3. Process tracks sequentially starting from startIndex
    final tracksToProcess = source.tracks.sublist(startIndex);

    for (final track in tracksToProcess) {
      if (_isPreloadCancelled) {
        logger.d('Smart Pre-Load: Cancelled for ${source.id}');
        return;
      }

      await _preloadTrack(track);
    }

    logger.i('Smart Pre-Load: Finished for source ${source.id}');
    _activePreloadSourceId = null;
  }

  Future<void> _preloadTrack(Track track) async {
    final key = sha256.convert(utf8.encode(track.url)).toString();
    final file = File('${_cacheDir!.path}/$key');

    // 1. Skip if already cached
    if (await file.exists()) {
      return;
    }

    // 2. Skip if already preloading this URL (safety)
    if (_preloadingUrls.contains(track.url)) {
      return;
    }

    _preloadingUrls.add(track.url);

    try {
      final tempFile = File('${file.path}.part');
      logger.d('Smart Pre-Load: Downloading ${track.title}...');

      final response = await _httpClient!.get(Uri.parse(track.url));
      if (_isPreloadCancelled) return;

      if (response.statusCode == 200) {
        await tempFile.writeAsBytes(response.bodyBytes);
        if (_isPreloadCancelled) {
          if (await tempFile.exists()) await tempFile.delete();
          return;
        }
        await tempFile.rename(file.path);
        logger.d('Smart Pre-Load: ✓ Cached ${track.title}');
        await refreshCacheCount();
      } else {
        logger.w(
            'Smart Pre-Load: Failed to download ${track.title} (HTTP ${response.statusCode})');
      }
    } catch (e) {
      logger.w('Smart Pre-Load: Error downloading ${track.title}: $e');
    } finally {
      _preloadingUrls.remove(track.url);
    }
  }
}
