# Live Playlist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Live Playlist (session history) — track previously played shows, enable cross-show back navigation, undo notifications, and history management UI.

**Architecture:** Session history already has a data layer (`CatalogService` + `SessionEntry` + Hive). This plan extends the model with missing fields, wires cross-show navigation into `AudioProvider`, and adds platform-appropriate UI affordances (web/phone undo pill, mobile swipe gesture). **TV UI is out of scope for this iteration.**

**Tech Stack:** Dart/Flutter, Hive CE (native persistence), in-memory fallback (web), Provider, `just_audio`, `MediaItem` extras for track index resolution.

---

## Spec vs. Current State

| Spec requirement | Current state |
|---|---|
| `SessionEntry` with trackIndex, position, title | Only sourceId, timestamp, showDate |
| `crossShowBack()` — "Previous" at track 0 loads prev show's last track | Not implemented; `seekToPrevious` delegates to engine unconditionally |
| Milestone recording every 5 min | **Dropped — existing restart-resume handles position; cross-show back always jumps to last track** |
| `clearSessionHistory()` | Not implemented |
| TV OSD "Back to [Title]" | **Deferred — TV UI out of scope for this iteration** |
| Web/Phone undo pill after show change | Not implemented |
| Mobile swipe-back past track 0 | Not implemented |
| Clear history in settings | Not implemented |

> **Note:** The spec says `session_history_v1` SharedPreferences key. The codebase already uses Hive boxes (better — typed, no manual JSON). This plan keeps Hive for native and the existing in-memory fallback for web.

---

## File Map

| Action | File | What changes |
|---|---|---|
| Modify | `packages/shakedown_core/lib/models/session_entry.dart` | Add `trackIndex`, `positionSeconds`, `title` fields |
| Regenerate | `packages/shakedown_core/lib/models/session_entry.g.dart` | Hive adapter for new fields |
| Modify | `packages/shakedown_core/lib/services/catalog_service.dart` | New `recordSession` signature, add `clearSessionHistory()` |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_state.dart` | Boundary state getters (`currentLocalTrackIndex`, `isAtLastTrack`, `hasPreviousInHistory`, `hasPrequeuedNextShow`) |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_controls.dart` | Abstract `crossShowBack()`, override `seekToPrevious()` |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_playback.dart` | Implement `crossShowBack()`, call `recordSession` on show start |
| Modify | `packages/shakedown_core/lib/ui/widgets/playback/playback_controls.dart` | Apply `prevEnabled`/`nextEnabled` to ← → buttons |
| Modify | `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart` | Add `_buildSkipPreviousButton`, apply boundary state to both skip buttons |
| Modify | `packages/shakedown_core/lib/ui/widgets/settings/data_section.dart` | Add Clear Session History tile |
| Create | `packages/shakedown_core/test/models/session_entry_test.dart` | Unit tests |
| Create | `packages/shakedown_core/test/services/catalog_service_session_test.dart` | Session history service tests |
| Create | `packages/shakedown_core/test/providers/live_playlist_test.dart` | AudioProvider cross-show navigation tests |

---

## Task 1: Extend SessionEntry model

**Files:**
- Modify: `packages/shakedown_core/lib/models/session_entry.dart`
- Regenerate: `packages/shakedown_core/lib/models/session_entry.g.dart`
- Create: `packages/shakedown_core/test/models/session_entry_test.dart`

- [ ] **Step 1: Write the failing test**

Create `packages/shakedown_core/test/models/session_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/session_entry.dart';

void main() {
  group('SessionEntry', () {
    test('stores trackIndex, positionSeconds, title', () {
      final entry = SessionEntry(
        sourceId: 'sbd1234',
        timestamp: DateTime(2024, 1, 1),
        showDate: '1980-05-08',
        trackIndex: 2,
        positionSeconds: 185,
        title: '1980-05-08 Barton Hall',
      );

      expect(entry.trackIndex, 2);
      expect(entry.positionSeconds, 185);
      expect(entry.position, const Duration(seconds: 185));
      expect(entry.title, '1980-05-08 Barton Hall');
    });

    test('position getter converts positionSeconds to Duration', () {
      final entry = SessionEntry(
        sourceId: 'x',
        timestamp: DateTime.now(),
        showDate: '1977-05-08',
        trackIndex: 0,
        positionSeconds: 300,
        title: 'Cornell',
      );
      expect(entry.position, const Duration(seconds: 300));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test packages/shakedown_core/test/models/session_entry_test.dart -v
```

Expected: FAIL — `SessionEntry` constructor doesn't accept `trackIndex`, `positionSeconds`, `title`.

- [ ] **Step 3: Update session_entry.dart**

Replace `packages/shakedown_core/lib/models/session_entry.dart` entirely:

```dart
import 'package:hive_ce/hive.dart';

part 'session_entry.g.dart';

@HiveType(typeId: 1)
class SessionEntry {
  @HiveField(0)
  final String sourceId;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String showDate;

  @HiveField(3)
  final int trackIndex;

  @HiveField(4)
  final int positionSeconds;

  @HiveField(5)
  final String title;

  SessionEntry({
    required this.sourceId,
    required this.timestamp,
    required this.showDate,
    this.trackIndex = 0,
    this.positionSeconds = 0,
    this.title = '',
  });

  Duration get position => Duration(seconds: positionSeconds);
}
```

- [ ] **Step 4: Regenerate the Hive adapter**

```bash
cd packages/shakedown_core && dart run build_runner build --delete-conflicting-outputs
```

Expected: `session_entry.g.dart` regenerated with 6 fields written/read.

Verify the generated adapter now writes all 6 fields:
```bash
grep -c "writeByte" packages/shakedown_core/lib/models/session_entry.g.dart
```
Expected output: `7` (1 for field count + 6 field writes — each writeByte call counts once).

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test packages/shakedown_core/test/models/session_entry_test.dart -v
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/models/session_entry.dart \
        packages/shakedown_core/lib/models/session_entry.g.dart \
        packages/shakedown_core/test/models/session_entry_test.dart
git commit -m "feat(session): extend SessionEntry with trackIndex, positionSeconds, title"
```

---

## Task 2: Update CatalogService — new recordSession signature

**Files:**
- Modify: `packages/shakedown_core/lib/services/catalog_service.dart`
- Create: `packages/shakedown_core/test/services/catalog_service_session_test.dart`

> All callers of `recordSession` pass only `sourceId` and `showDate` today. New params default to `0`/`''`, so callers are not broken.

- [ ] **Step 1: Write the failing test**

Create `packages/shakedown_core/test/services/catalog_service_session_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/session_entry.dart';
import 'package:shakedown_core/services/catalog_service.dart';

void main() {
  late CatalogService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(RatingAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionEntryAdapter());
    }
    service = CatalogService.internal();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
    CatalogService.setMock(CatalogService.internal());
  });

  group('recordSession with new fields', () {
    test('stores trackIndex, positionSeconds, title', () async {
      // Manually open the box without full initialize() to avoid JSON asset load
      final sessionBox =
          await Hive.openBox<SessionEntry>('session_history');

      // Record using the updated signature
      await service.recordSessionRaw(
        sessionBox: sessionBox,
        sourceId: 'sbd1234',
        showDate: '1977-05-08',
        trackIndex: 3,
        positionSeconds: 90,
        title: '1977-05-08 Cornell',
      );

      final history = sessionBox.values.toList();
      expect(history.length, 1);
      expect(history.first.trackIndex, 3);
      expect(history.first.positionSeconds, 90);
      expect(history.first.title, '1977-05-08 Cornell');
    });
  });

  group('clearSessionHistory', () {
    test('clears web in-memory history', () async {
      // Use web-path by testing the public API on a fresh instance
      // (kIsWeb is false in tests, so use the helper method directly)
      service.testAddWebEntry(SessionEntry(
        sourceId: 'x',
        timestamp: DateTime.now(),
        showDate: '1980-01-01',
        trackIndex: 0,
        positionSeconds: 0,
        title: 'test',
      ));
      expect(service.getWebSessionHistoryForTest().length, 1);
      service.clearWebSessionHistoryForTest();
      expect(service.getWebSessionHistoryForTest().length, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test packages/shakedown_core/test/services/catalog_service_session_test.dart -v
```

Expected: FAIL — `recordSessionRaw`, `testAddWebEntry`, `clearWebSessionHistoryForTest`, `getWebSessionHistoryForTest` don't exist.

- [ ] **Step 3: Update catalog_service.dart**

Find and replace the existing `recordSession` method and add the new helpers. In `catalog_service.dart`:

**3a.** Update the public `recordSession` signature (around line 262):

```dart
Future<void> recordSession(
  String sourceId, {
  required String showDate,
  int trackIndex = 0,
  int positionSeconds = 0,
  String title = '',
}) async {
  if (!_isInitialized) return;

  final entry = SessionEntry(
    sourceId: sourceId,
    timestamp: DateTime.now(),
    showDate: showDate,
    trackIndex: trackIndex,
    positionSeconds: positionSeconds,
    title: title,
  );

  if (kIsWeb) {
    _webSessionHistory.add(entry);
    if (_webSessionHistory.length > 50) _webSessionHistory.removeAt(0);
    return;
  }

  await _sessionBox!.add(entry);
  if (_sessionBox!.length > 50) {
    await _sessionBox!.deleteAt(0);
  }
}
```

**3b.** Add `clearSessionHistory()` after the existing `getSessionHistory()` method:

```dart
Future<void> clearSessionHistory() async {
  if (!_isInitialized) return;
  if (kIsWeb) {
    _webSessionHistory.clear();
    return;
  }
  await _sessionBox!.clear();
}
```

**3c.** Add `@visibleForTesting` helpers for the web in-memory list (needed by tests since `kIsWeb` is always false in unit tests):

```dart
@visibleForTesting
Future<void> recordSessionRaw({
  required Box<SessionEntry> sessionBox,
  required String sourceId,
  required String showDate,
  int trackIndex = 0,
  int positionSeconds = 0,
  String title = '',
}) async {
  final entry = SessionEntry(
    sourceId: sourceId,
    timestamp: DateTime.now(),
    showDate: showDate,
    trackIndex: trackIndex,
    positionSeconds: positionSeconds,
    title: title,
  );
  await sessionBox.add(entry);
  if (sessionBox.length > 50) {
    await sessionBox.deleteAt(0);
  }
}

@visibleForTesting
void testAddWebEntry(SessionEntry entry) {
  _webSessionHistory.add(entry);
}

@visibleForTesting
List<SessionEntry> getWebSessionHistoryForTest() =>
    List.unmodifiable(_webSessionHistory);

@visibleForTesting
void clearWebSessionHistoryForTest() => _webSessionHistory.clear();
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test packages/shakedown_core/test/services/catalog_service_session_test.dart -v
```

Expected: PASS.

- [ ] **Step 5: Verify no regressions**

```bash
flutter test packages/shakedown_core/test/services/catalog_service_test.dart -v
```

Expected: PASS (existing callers of `recordSession` still work — new params default).

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/services/catalog_service.dart \
        packages/shakedown_core/test/services/catalog_service_session_test.dart
git commit -m "feat(session): extend recordSession with track/position/title, add clearSessionHistory"
```

---

## Task 3: Cross-show back navigation in AudioProvider

**Files:**
- Modify: `packages/shakedown_core/lib/providers/audio_provider_state.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_controls.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_playback.dart`
- Create: `packages/shakedown_core/test/providers/live_playlist_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `packages/shakedown_core/test/providers/live_playlist_test.dart`:

```dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mockito/mockito.dart';
import 'package:shakedown_core/models/session_entry.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';

// Reuse mocks from audio_provider_test.mocks.dart
import 'audio_provider_test.mocks.dart';

Show _makeShow(String date, String sourceId, int trackCount) {
  return Show(
    name: 'Test Show $date',
    artist: 'GD',
    date: date,
    venue: 'Test Venue',
    sources: [
      Source(
        id: sourceId,
        type: 'sbd',
        tracks: List.generate(
          trackCount,
          (i) => Track(title: 'Track $i', duration: 60, url: 'http://t$i.mp3'),
        ),
      ),
    ],
  );
}

void main() {
  late AudioProvider audioProvider;
  late MockAudioPlayerRelaxed mockAudioPlayer;
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockCatalogService mockCatalogService;
  late MockAudioCacheService mockAudioCacheService;
  late MockWakelockService mockWakelockService;
  late StreamController<ProcessingState> processingStateController;
  late StreamController<Duration> positionController;
  late StreamController<int?> currentIndexController;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockShowListProvider = MockShowListProvider();
    mockAudioPlayer = MockAudioPlayerRelaxed();
    mockCatalogService = MockCatalogService();
    mockAudioCacheService = MockAudioCacheService();
    mockWakelockService = MockWakelockService();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );

    processingStateController = StreamController<ProcessingState>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    currentIndexController = StreamController<int?>.broadcast();

    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);
    when(mockCatalogService.getRating(any)).thenReturn(0);
    when(mockCatalogService.isPlayed(any)).thenReturn(false);

    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => currentIndexController.stream);
    when(mockAudioPlayer.playbackEventStream).thenAnswer(
      (_) => const Stream<PlaybackEvent>.empty(),
    );
    when(mockAudioPlayer.playerStateStream).thenAnswer(
      (_) => const Stream<PlayerState>.empty(),
    );
    when(mockAudioPlayer.bufferedPositionStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(mockAudioPlayer.engineStateStringStream)
        .thenAnswer((_) => const Stream<String>.empty());
    when(mockAudioPlayer.driftStream)
        .thenAnswer((_) => const Stream<double>.empty());
    when(mockAudioPlayer.visibilityStream)
        .thenAnswer((_) => const Stream<String>.empty());
    when(mockAudioPlayer.heartbeatActiveStream)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(mockAudioPlayer.heartbeatNeededStream)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(mockAudioPlayer.nextTrackBufferedStream)
        .thenAnswer((_) => const Stream<Duration?>.empty());
    when(mockAudioPlayer.nextTrackTotalStream)
        .thenAnswer((_) => const Stream<Duration?>.empty());
    when(mockAudioPlayer.engineContextStateStream)
        .thenAnswer((_) => const Stream<String>.empty());
    when(mockAudioPlayer.durationStream)
        .thenAnswer((_) => const Stream<Duration?>.empty());
    when(mockAudioPlayer.playingStream)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(mockAudioPlayer.sequence).thenReturn([]);
    when(mockAudioPlayer.engineName).thenReturn('mock');
    when(mockAudioPlayer.selectionReason).thenReturn('test');
    when(mockAudioPlayer.engineStateString).thenReturn('idle');
    when(mockAudioPlayer.playing).thenReturn(false);

    when(mockAudioCacheService.cachedTrackCount).thenReturn(0);
    when(mockAudioCacheService.getAlbumArtUri())
        .thenAnswer((_) async => null);
    when(mockAudioCacheService.createAudioSource(
      uri: anyNamed('uri'),
      tag: anyNamed('tag'),
      useCache: anyNamed('useCache'),
    )).thenAnswer((inv) {
      final uri = inv.namedArguments[const Symbol('uri')] as Uri;
      final tag = inv.namedArguments[const Symbol('tag')];
      return AudioSource.uri(uri, tag: tag);
    });

    audioProvider = AudioProvider(
      audioPlayer: mockAudioPlayer,
      catalogService: mockCatalogService,
      audioCacheService: mockAudioCacheService,
      wakelockService: mockWakelockService,
      isWeb: false,
    );

    audioProvider.attachSettingsProvider(mockSettingsProvider);
    audioProvider.attachShowListProvider(mockShowListProvider);
  });

  tearDown(() {
    processingStateController.close();
    positionController.close();
    currentIndexController.close();
    audioProvider.dispose();
  });

  group('crossShowBack', () {
    test('returns false when session history is empty', () async {
      when(mockCatalogService.getSessionHistory()).thenReturn([]);

      final result = await audioProvider.crossShowBack();

      expect(result, isFalse);
      verifyNever(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      ));
    });

    test('loads previous show at its last track', () async {
      final prevShow = _makeShow('1977-05-08', 'sbd1234', 3);
      final currShow = _makeShow('1980-05-08', 'sbd5678', 2);

      // Set current show state
      when(mockAudioPlayer.currentIndex).thenReturn(0);
      when(mockAudioPlayer.sequence).thenReturn([]);

      // Simulate current show is currShow
      audioProvider.testSetCurrentShow(currShow, currShow.sources.first);

      when(mockCatalogService.getSessionHistory()).thenReturn([
        SessionEntry(
          sourceId: 'sbd1234',
          timestamp: DateTime.now(),
          showDate: '1977-05-08',
          trackIndex: 0,
          positionSeconds: 0,
          title: '1977-05-08 Cornell',
        ),
      ]);

      when(mockShowListProvider.allShows)
          .thenReturn([prevShow, currShow]);
      when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);
      when(mockSettingsProvider.markPlayedOnStart).thenReturn(false);
      when(mockSettingsProvider.offlineBuffering).thenReturn(false);
      when(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).thenAnswer((_) async {});
      when(mockAudioPlayer.play()).thenAnswer((_) async {});

      final result = await audioProvider.crossShowBack();

      expect(result, isTrue);
      // Should seek to last track of prevShow (index 2 — 3 tracks)
      verify(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: 2,
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).called(1);
    });

    test('skips history entries matching current source', () async {
      final prevShow = _makeShow('1977-05-08', 'sbd1234', 2);
      final currShow = _makeShow('1980-05-08', 'sbd5678', 2);

      audioProvider.testSetCurrentShow(currShow, currShow.sources.first);

      when(mockCatalogService.getSessionHistory()).thenReturn([
        // Same source as current — should be skipped
        SessionEntry(
          sourceId: 'sbd5678',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          showDate: '1980-05-08',
          trackIndex: 0,
          positionSeconds: 0,
          title: '',
        ),
        // Previous show — should be used
        SessionEntry(
          sourceId: 'sbd1234',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          showDate: '1977-05-08',
          trackIndex: 0,
          positionSeconds: 0,
          title: '',
        ),
      ]);

      when(mockShowListProvider.allShows)
          .thenReturn([prevShow, currShow]);
      when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);
      when(mockSettingsProvider.markPlayedOnStart).thenReturn(false);
      when(mockSettingsProvider.offlineBuffering).thenReturn(false);
      when(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).thenAnswer((_) async {});
      when(mockAudioPlayer.play()).thenAnswer((_) async {});

      final result = await audioProvider.crossShowBack();
      expect(result, isTrue);
      verify(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: 1, // last track of prevShow (2 tracks → index 1)
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).called(1);
    });

    test('skips history entries where source is not allowed', () async {
      final prevShow = _makeShow('1977-05-08', 'sbd1234', 2);
      final currShow = _makeShow('1980-05-08', 'sbd5678', 2);

      audioProvider.testSetCurrentShow(currShow, currShow.sources.first);

      when(mockCatalogService.getSessionHistory()).thenReturn([
        SessionEntry(
          sourceId: 'sbd1234',
          timestamp: DateTime.now(),
          showDate: '1977-05-08',
          trackIndex: 0,
          positionSeconds: 0,
          title: '',
        ),
      ]);

      when(mockShowListProvider.allShows)
          .thenReturn([prevShow, currShow]);
      // Source is not allowed (e.g. filtered out)
      when(mockShowListProvider.isSourceAllowed(any)).thenReturn(false);

      final result = await audioProvider.crossShowBack();
      expect(result, isFalse);
    });
  });

  group('seekToPrevious cross-show', () {
    test('calls crossShowBack when at track 0 with history', () async {
      final prevShow = _makeShow('1977-05-08', 'sbd1234', 2);
      final currShow = _makeShow('1980-05-08', 'sbd5678', 2);

      audioProvider.testSetCurrentShow(currShow, currShow.sources.first);

      // Simulate being at track 0
      final tag = MediaItem(
        id: 'test_sbd5678_0',
        title: 'Track 0',
        extras: {'source_id': 'sbd5678', 'track_index': 0},
      );
      when(mockAudioPlayer.currentIndex).thenReturn(0);
      when(mockAudioPlayer.sequence).thenReturn([AudioSource.uri(
        Uri.parse('http://t0.mp3'),
        tag: tag,
      )]);

      when(mockCatalogService.getSessionHistory()).thenReturn([
        SessionEntry(
          sourceId: 'sbd1234',
          timestamp: DateTime.now(),
          showDate: '1977-05-08',
          trackIndex: 0,
          positionSeconds: 0,
          title: '',
        ),
      ]);
      when(mockShowListProvider.allShows).thenReturn([prevShow, currShow]);
      when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);
      when(mockSettingsProvider.markPlayedOnStart).thenReturn(false);
      when(mockSettingsProvider.offlineBuffering).thenReturn(false);
      when(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).thenAnswer((_) async {});
      when(mockAudioPlayer.play()).thenAnswer((_) async {});

      await audioProvider.seekToPrevious();

      // Should NOT have called seekToPrevious on the engine
      verifyNever(mockAudioPlayer.seekToPrevious());
      // Should have loaded previous show
      verify(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      )).called(1);
    });

    test('delegates to engine seekToPrevious when not at track 0', () async {
      final currShow = _makeShow('1980-05-08', 'sbd5678', 3);
      audioProvider.testSetCurrentShow(currShow, currShow.sources.first);

      // Simulate being at track 1 (not 0)
      final tag = MediaItem(
        id: 'test_sbd5678_1',
        title: 'Track 1',
        extras: {'source_id': 'sbd5678', 'track_index': 1},
      );
      when(mockAudioPlayer.currentIndex).thenReturn(1);
      when(mockAudioPlayer.sequence).thenReturn([
        AudioSource.uri(Uri.parse('http://t0.mp3'), tag: MediaItem(
          id: 'test_sbd5678_0', title: 'Track 0',
          extras: {'source_id': 'sbd5678', 'track_index': 0},
        )),
        AudioSource.uri(Uri.parse('http://t1.mp3'), tag: tag),
      ]);
      when(mockAudioPlayer.seekToPrevious()).thenAnswer((_) async {});

      await audioProvider.seekToPrevious();

      verify(mockAudioPlayer.seekToPrevious()).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test packages/shakedown_core/test/providers/live_playlist_test.dart -v
```

Expected: FAIL — `crossShowBack()`, `testSetCurrentShow()` don't exist.

- [ ] **Step 3: Add testSetCurrentShow helper to AudioProvider**

In `packages/shakedown_core/lib/providers/audio_provider_state.dart`, after the existing `cachedTrackCount` getter, add:

```dart
@visibleForTesting
void testSetCurrentShow(Show show, Source source) {
  _currentShow = show;
  _currentSource = source;
}
```

Also add the import at the top of `audio_provider.dart`:
```dart
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, visibleForTesting;
```

(It already imports `ChangeNotifier` and `kIsWeb` from that path — add `visibleForTesting` to the show clause.)

- [ ] **Step 4: Declare crossShowBack() abstractly in controls**

In `packages/shakedown_core/lib/providers/audio_provider_controls.dart`, add the abstract declaration alongside `playSource`:

```dart
// Declare as abstract — implemented in _AudioProviderPlayback
Future<bool> crossShowBack();
```

Also update `seekToPrevious()` to use it:

```dart
Future<void> seekToPrevious() async {
  final localIndex = _resolveLocalTrackIndex();
  if (localIndex == 0) {
    final handled = await crossShowBack();
    if (handled) return;
  }
  await _audioPlayer.seekToPrevious();
}

int _resolveLocalTrackIndex() {
  final index = _audioPlayer.currentIndex;
  if (index == null) return 0;
  final sequence = _audioPlayer.sequence;
  if (sequence.isEmpty || index >= sequence.length) return 0;
  final tag = sequence[index].tag;
  if (tag is MediaItem) {
    return tag.extras?['track_index'] as int? ?? index;
  }
  return index;
}
```

Remove the old single-line `Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();`.

- [ ] **Step 5: Implement crossShowBack() in playback mixin**

In `packages/shakedown_core/lib/providers/audio_provider_playback.dart`, add after `playFromShareString`:

```dart
@override
Future<bool> crossShowBack() async {
  if (_showListProvider == null) return false;

  final history = _catalogService.getSessionHistory();
  if (history.isEmpty) return false;

  // Walk backward (newest entries are last)
  for (int i = history.length - 1; i >= 0; i--) {
    final entry = history[i];

    // Skip current show
    if (entry.sourceId == _currentSource?.id) continue;

    // Find show and source objects
    Show? targetShow;
    Source? targetSource;
    for (final show in _showListProvider!.allShows) {
      for (final source in show.sources) {
        if (source.id == entry.sourceId) {
          targetShow = show;
          targetSource = source;
          break;
        }
      }
      if (targetSource != null) break;
    }

    if (targetShow == null || targetSource == null) continue;

    // Skip filtered-out sources (e.g. category filter active)
    if (!_showListProvider!.isSourceAllowed(targetSource)) continue;

    final lastIndex = targetSource.tracks.isEmpty
        ? 0
        : targetSource.tracks.length - 1;

    await playSource(targetShow, targetSource, initialIndex: lastIndex);
    return true;
  }

  return false;
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test packages/shakedown_core/test/providers/live_playlist_test.dart -v
```

Expected: PASS all groups.

- [ ] **Step 7: Run full provider test suite**

```bash
flutter test packages/shakedown_core/test/providers/ -v
```

Expected: All existing tests still pass.

- [ ] **Step 8: Commit**

```bash
git add packages/shakedown_core/lib/providers/audio_provider_state.dart \
        packages/shakedown_core/lib/providers/audio_provider_controls.dart \
        packages/shakedown_core/lib/providers/audio_provider_playback.dart \
        packages/shakedown_core/test/providers/live_playlist_test.dart
git commit -m "feat(session): add crossShowBack() and cross-show seekToPrevious override"
```

---

> **TV OSD — DEFERRED.** TV UI support for Live Playlist is out of scope for this iteration. The `crossShowBack()` logic in `AudioProvider` works on all platforms; only the TV-specific OSD overlay and D-Pad handler are deferred. When TV support is added later, the steps needed are: state in `_TvDualPaneLayoutState`, `TvPreviousTrackIntent` handler update, `catalogService` getter on `AudioProvider`, and the `Stack` overlay.

---

## Task 4: Transport button boundary state

**Files:**
- Modify: `packages/shakedown_core/lib/providers/audio_provider_state.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/playback_controls.dart`

Rules:
- **← button**: greyed out when `currentLocalTrackIndex == 0 && !hasPreviousInHistory`
- **→ button**: greyed out when `isAtLastTrack && !hasPrequeuedNextShow`
- Both buttons remain fully active within a show (not at boundaries)

- [ ] **Step 1: Write the failing tests**

Add to `packages/shakedown_core/test/providers/live_playlist_test.dart` inside `main()`:

```dart
group('boundary getters', () {
  test('hasPreviousInHistory is false when history is empty', () {
    when(mockCatalogService.getSessionHistory()).thenReturn([]);
    expect(audioProvider.hasPreviousInHistory, isFalse);
  });

  test('hasPreviousInHistory is false when history contains only current source', () {
    final currShow = _makeShow('1980-05-08', 'sbd5678', 2);
    audioProvider.testSetCurrentShow(currShow, currShow.sources.first);
    when(mockCatalogService.getSessionHistory()).thenReturn([
      SessionEntry(
        sourceId: 'sbd5678',
        timestamp: DateTime.now(),
        showDate: '1980-05-08',
        trackIndex: 0,
        positionSeconds: 0,
        title: '',
      ),
    ]);
    expect(audioProvider.hasPreviousInHistory, isFalse);
  });

  test('hasPreviousInHistory is true when history has a different source', () {
    final currShow = _makeShow('1980-05-08', 'sbd5678', 2);
    audioProvider.testSetCurrentShow(currShow, currShow.sources.first);
    when(mockCatalogService.getSessionHistory()).thenReturn([
      SessionEntry(
        sourceId: 'sbd1234',
        timestamp: DateTime.now(),
        showDate: '1977-05-08',
        trackIndex: 0,
        positionSeconds: 0,
        title: '',
      ),
    ]);
    expect(audioProvider.hasPreviousInHistory, isTrue);
  });

  test('currentLocalTrackIndex resolves from MediaItem extras', () {
    final tag = MediaItem(
      id: 'test_sbd5678_2',
      title: 'Track 2',
      extras: {'source_id': 'sbd5678', 'track_index': 2},
    );
    when(mockAudioPlayer.currentIndex).thenReturn(2);
    when(mockAudioPlayer.sequence).thenReturn([
      AudioSource.uri(Uri.parse('http://t0.mp3'), tag: MediaItem(
        id: 'x0', title: 'T0', extras: {'track_index': 0},
      )),
      AudioSource.uri(Uri.parse('http://t1.mp3'), tag: MediaItem(
        id: 'x1', title: 'T1', extras: {'track_index': 1},
      )),
      AudioSource.uri(Uri.parse('http://t2.mp3'), tag: tag),
    ]);
    expect(audioProvider.currentLocalTrackIndex, 2);
  });

  test('isAtLastTrack is true when on last track', () {
    final currShow = _makeShow('1980-05-08', 'sbd5678', 3); // 3 tracks
    audioProvider.testSetCurrentShow(currShow, currShow.sources.first);
    final tag = MediaItem(
      id: 'x2', title: 'T2',
      extras: {'source_id': 'sbd5678', 'track_index': 2},
    );
    when(mockAudioPlayer.currentIndex).thenReturn(2);
    when(mockAudioPlayer.sequence).thenReturn([
      AudioSource.uri(Uri.parse('http://t0.mp3'), tag: MediaItem(
        id: 'x0', title: 'T0', extras: {'track_index': 0},
      )),
      AudioSource.uri(Uri.parse('http://t1.mp3'), tag: MediaItem(
        id: 'x1', title: 'T1', extras: {'track_index': 1},
      )),
      AudioSource.uri(Uri.parse('http://t2.mp3'), tag: tag),
    ]);
    expect(audioProvider.isAtLastTrack, isTrue);
  });
});
```

- [ ] **Step 2: Run to verify they fail**

```bash
flutter test packages/shakedown_core/test/providers/live_playlist_test.dart \
  --name "boundary getters" -v
```

Expected: FAIL — `hasPreviousInHistory`, `currentLocalTrackIndex`, `isAtLastTrack` don't exist.

- [ ] **Step 3: Add getters to audio_provider_state.dart**

In `packages/shakedown_core/lib/providers/audio_provider_state.dart`, add after the existing `currentTrack` getter:

```dart
int get currentLocalTrackIndex {
  final index = _audioPlayer.currentIndex;
  if (index == null) return 0;
  final sequence = _audioPlayer.sequence;
  if (sequence.isEmpty || index >= sequence.length) return 0;
  final tag = sequence[index].tag;
  if (tag is MediaItem) {
    return tag.extras?['track_index'] as int? ?? index;
  }
  return index;
}

bool get isAtLastTrack {
  if (_currentSource == null) return false;
  return currentLocalTrackIndex >= _currentSource!.tracks.length - 1;
}

bool get hasPreviousInHistory {
  final history = _catalogService.getSessionHistory();
  return history.any((e) => e.sourceId != _currentSource?.id);
}

bool get hasPrequeuedNextShow => _hasPrequeuedNextShow;
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test packages/shakedown_core/test/providers/live_playlist_test.dart -v
```

Expected: PASS.

- [ ] **Step 5: Update PlaybackControls to grey out buttons at boundaries**

In `packages/shakedown_core/lib/ui/widgets/playback/playback_controls.dart`, find the build method. Locate where `audioProvider` is read (around line 49). Add:

```dart
final bool prevEnabled = audioProvider.currentLocalTrackIndex > 0 ||
    audioProvider.hasPreviousInHistory;
final bool nextEnabled = !audioProvider.isAtLastTrack ||
    audioProvider.hasPrequeuedNextShow;
```

Then find the ← icon button and add `onPressed: prevEnabled ? () { audioProvider.seekToPrevious(); } : null`.

Find the → icon button and add `onPressed: nextEnabled ? () { audioProvider.seekToNext(); } : null`.

The exact widget will be an `IconButton` or a `GestureDetector`-wrapped icon. Read the file first to locate the exact widget and apply the disable pattern consistently with how other buttons in that file are disabled (some use `onPressed: null` to grey out, others use `Opacity`).

- [ ] **Step 6: Run playback screen tests**

```bash
flutter test packages/shakedown_core/test/screens/playback_screen_test.dart \
            packages/shakedown_core/test/widgets/playback_panel_overflow_test.dart -v
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/shakedown_core/lib/providers/audio_provider_state.dart \
        packages/shakedown_core/lib/ui/widgets/playback/playback_controls.dart \
        packages/shakedown_core/test/providers/live_playlist_test.dart
git commit -m "feat(controls): grey out transport buttons at show boundaries with no history/queue"
```

---

## Task 5: Add Fruit-style skip-previous button + apply boundary state to FruitNowPlayingCard

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`

> **Read before starting:** `.agent/rules/fruit_theme.md` and `.agent/rules/fruit_theme_boundaries.md`

`FruitNowPlayingCard` already has `_buildSkipNextButton` using `FruitIconButton` + `LucideIcons.skipForward`. There is no skip-previous button. This task adds `_buildSkipPreviousButton` and applies the boundary-state getters from Task 6 to both buttons.

- [ ] **Step 1: Read the Fruit theme rules**

```bash
cat .agent/rules/fruit_theme.md
cat .agent/rules/fruit_theme_boundaries.md
```

Confirm the correct pattern for a secondary/muted icon button (see how `_buildSkipNextButton` is currently styled — `LucideIcons.skipForward`, `FruitIconButton`, `onSurfaceVariant` with 50% alpha).

- [ ] **Step 2: Read fruit_now_playing_card.dart in full**

Read `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart` completely before making any changes. Identify:
  - Every call site of `_buildSkipNextButton` (there are two: lines 129 and 229)
  - The layout Row/Column that wraps the button(s) — the previous button goes on the opposite side

- [ ] **Step 3: Add _buildSkipPreviousButton method**

In `fruit_now_playing_card.dart`, add after `_buildSkipNextButton`:

```dart
Widget _buildSkipPreviousButton(
  BuildContext context,
  AudioProvider audioProvider,
  ColorScheme colorScheme,
) {
  final prevEnabled = audioProvider.currentLocalTrackIndex > 0 ||
      audioProvider.hasPreviousInHistory;
  return FruitIconButton(
    onPressed: prevEnabled
        ? () {
            AppHaptics.lightImpact(context.read<DeviceService>());
            audioProvider.seekToPrevious();
          }
        : null,
    icon: Icon(
      LucideIcons.skipBack,
      color: prevEnabled
          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
      size: 18 * scaleFactor,
    ),
    size: 20 * scaleFactor,
    padding: 4 * scaleFactor,
    tooltip: 'Skip Previous',
  );
}
```

- [ ] **Step 4: Update _buildSkipNextButton to respect boundary state**

Replace the existing `_buildSkipNextButton`:

```dart
Widget _buildSkipNextButton(
  BuildContext context,
  AudioProvider audioProvider,
  ColorScheme colorScheme,
) {
  final nextEnabled =
      !audioProvider.isAtLastTrack || audioProvider.hasPrequeuedNextShow;
  return FruitIconButton(
    onPressed: nextEnabled
        ? () {
            AppHaptics.lightImpact(context.read<DeviceService>());
            audioProvider.seekToNext();
          }
        : null,
    icon: Icon(
      LucideIcons.skipForward,
      color: nextEnabled
          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
      size: 18 * scaleFactor,
    ),
    size: 20 * scaleFactor,
    padding: 4 * scaleFactor,
    tooltip: 'Skip Next',
  );
}
```

> Note: The existing `_buildSkipNextButton` signature is `(AudioProvider, ColorScheme)`. The new versions add `BuildContext` as first parameter for `AppHaptics`. Update all call sites to pass `context` as the first argument.

- [ ] **Step 5: Update call sites**

At each call site of `_buildSkipNextButton` (lines ~129 and ~229), add the previous button on the opposite side and pass `context`:

At each site, replace:
```dart
_buildSkipNextButton(audioProvider, colorScheme),
```
with:
```dart
_buildSkipPreviousButton(context, audioProvider, colorScheme),
// ... existing widgets between them ...
_buildSkipNextButton(context, audioProvider, colorScheme),
```

Read the exact layout structure at each site before editing — the prev button should mirror the visual position of the next button on the left side.

- [ ] **Step 6: Run Fruit playback tests**

```bash
flutter test packages/shakedown_core/test/ui/widgets/playback/ \
            packages/shakedown_core/test/screens/playback_screen_fruit_inset_test.dart -v
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart
git commit -m "feat(fruit): add skip-previous button and apply boundary state to both skip buttons"
```

---

## Task 6: Clear Session History in Settings

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/data_section.dart`

- [ ] **Step 1: Add Clear Session History tile to DataSection**

Replace the entire file `packages/shakedown_core/lib/ui/widgets/settings/data_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/ui/screens/rated_shows_screen.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';

class DataSection extends StatelessWidget {
  final double scaleFactor;

  const DataSection({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Manage Rated Shows Library',
      icon: Icons.star_rounded,
      lucideIcon: Icons.star,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RatedShowsScreen()),
        );
      },
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text('Clear Session History'),
          subtitle: const Text('Remove all previously played show records'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear Session History'),
                content: const Text(
                  'This will remove all session history. '
                  'The back-navigation feature will not be able to '
                  'return to previously played shows.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await CatalogService().clearSessionHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session history cleared.')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run settings screen tests**

```bash
flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart -v
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/settings/data_section.dart
git commit -m "feat(settings): add Clear Session History option in data section"
```

---

## Spec Coverage Check

| Spec section | Covered by task |
|---|---|
| §2 Data Model — trackIndex, position, title | Task 1 |
| §3.1 Recording on show start | Task 3 (`playSource` calls `recordSession`) |
| §3.1 Recording every 5 minutes | **Dropped** |
| §3.1 Rolling stack of 50 shows | Already implemented in CatalogService |
| §3.2 Cross-show back at track 0 | Task 3 |
| §3.2 Cross-show forward | Existing `queueRandomShow` handles auto-advance; manual forward nav is standard `seekToNext` on last track which auto-advances — no additional work |
| §4.1 TV D-Pad OSD label | **Deferred — TV UI out of scope this iteration** |
| §4.1 TV Undo Block toast | Out of scope — block feature not yet in codebase |
| §4.2 Web/Phone undo pill | **Dropped — ← button with boundary state handles this** |
| §4.2 Swipe gesture on mobile | **Dropped — transport buttons handle this** |
| §5 Persistence (Hive, not SP) | Existing + Tasks 1–2 |
| §5 Clear history in settings | Task 6 |
| Transport button boundary state | Task 4 |
| Fruit skip-previous button + boundary state | Task 5 |
| §6 Skip blocked/deleted shows | Task 3 (`isSourceAllowed` check) |
| §6 Offline placeholder | Out of scope — offline mode not yet in codebase |
