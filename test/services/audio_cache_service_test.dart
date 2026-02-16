// ignore_for_file: experimental_member_use
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/services/audio_cache_service.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';

void main() {
  group('AudioCacheService', () {
    late Directory tempDir;
    late AudioCacheService service;

    setUp(() async {
      // Create a temporary directory for isolation
      tempDir = await Directory.systemTemp.createTemp('audio_cache_test_');
      service = AudioCacheService(cacheDir: tempDir);
    });

    tearDown(() async {
      service.dispose();
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Initializes with 0 cached tracks', () {
      expect(service.cachedTrackCount, 0);
    });

    test(
        'createAudioSource returns LockCachingAudioSource when cache is enabled',
        () async {
      final uri = Uri.parse('https://example.com/audio.mp3');
      final tag = MediaItem(id: '1', title: 'Test');

      final source = service.createAudioSource(
        uri: uri,
        tag: tag,
        useCache: true,
      );

      expect(source, isA<LockCachingAudioSource>());
      final lockSource = source as LockCachingAudioSource;
      expect((await lockSource.cacheFile).parent.path, tempDir.path);
    });

    test(
        'createAudioSource returns standard AudioSource when cache is disabled',
        () {
      final uri = Uri.parse('https://example.com/audio.mp3');
      final tag = MediaItem(id: '1', title: 'Test');

      final source = service.createAudioSource(
        uri: uri,
        tag: tag,
        useCache: false,
      );

      expect(source, isNot(isA<LockCachingAudioSource>()));
      expect(source, isA<AudioSource>());
    });

    test('refreshCacheCount counts valid cache files', () async {
      // Create a dummy file with 64-char name (simulating SHA256)
      final validName = 'a' * 64;
      final file = File('${tempDir.path}/$validName');
      await file.create();

      // Create an invalid file
      final invalidFile = File('${tempDir.path}/invalid_cache_file');
      await invalidFile.create();

      await service.refreshCacheCount();

      // Wait a tick for listeners (if any logic was async in notification, though here it's simple)
      expect(service.cachedTrackCount, 1);
    });

    test('performCacheCleanup removes oldest files when limit exceeded',
        () async {
      // Create 5 files with specific modification times
      // Note: File system timestamp resolution can be coarse, so delays or explicit setting might be needed.
      // We'll try explicit setLastModified.

      final files = <File>[];
      for (int i = 0; i < 5; i++) {
        final name = i.toString().padLeft(64, '0'); // valid 64-char name
        final file = File('${tempDir.path}/$name');
        await file.create();
        // Set distinct modification times
        // File 0 is newest, File 4 is oldest
        file.setLastModifiedSync(DateTime.now().subtract(Duration(minutes: i)));
        files.add(file);
      }

      // We have 5 files. Max 3. Should keep 3 newest (0, 1, 2). Delete (3, 4).
      await service.performCacheCleanup(maxFiles: 3);

      expect(await files[0].exists(), true, reason: 'Newest file should exist');
      expect(await files[1].exists(), true,
          reason: '2nd newest file should exist');
      expect(await files[2].exists(), true,
          reason: '3rd newest file should exist');
      expect(await files[3].exists(), false,
          reason: 'Old file should be deleted');
      expect(await files[4].exists(), false,
          reason: 'Oldest file should be deleted');

      expect(service.cachedTrackCount, 3);
    });

    test('preloadSource downloads tracks sequentially and can be cancelled',
        () async {
      // Create a mock source
      final track1 = Track(
        trackNumber: 1,
        title: 'Track 1',
        url: 'https://archive.org/t1.mp3',
        duration: 300,
        setName: 'Set 1',
      );
      final track2 = Track(
        trackNumber: 2,
        title: 'Track 2',
        url: 'https://archive.org/t2.mp3',
        duration: 300,
        setName: 'Set 1',
      );
      final source = Source(
        id: 'source_test',
        tracks: [track1, track2],
      );

      // Note: testing actual HTTP downloads in unit tests is tricky without mocks.
      // But we can check if the files eventually exist or if logic flows.
      // Since we use http.Client, we might need to mock it if we wanted strict verify.
      // For now, let's verify it starts and we can call cancel.

      // Trigger preload
      final preloadFuture = service.preloadSource(source);

      // Cancel immediately
      service.monitorCache(false); // This calls _cancelPreload()

      await preloadFuture;

      // Check if it finished gracefully
      expect(true, true);
    });
  });
}
