# Navigation Undo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-step, in-memory navigation undo that restores the previous show/track/position when the user presses `Previous` within the first 5 seconds after an accidental manual navigation.

**Architecture:** Keep undo state entirely inside `AudioProvider` as one ephemeral `UndoCheckpoint`. UI call sites explicitly capture a checkpoint before user-initiated navigation, while `seekToPrevious()` becomes the only restore consumer. No persistence, no history screen, and no settings toggle are added in v1.

**Tech Stack:** Dart, Flutter, Provider, `just_audio`, existing `AudioProvider` mixins, widget/provider tests

---

## File Map

| Action | File | What changes |
|---|---|---|
| Create | `packages/shakedown_core/lib/models/undo_checkpoint.dart` | Plain Dart model for one undo checkpoint with expiry helper |
| Modify | `packages/shakedown_core/lib/providers/audio_provider.dart` | Register `AudioProvider` as a lifecycle observer |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_state.dart` | Add undo fields, checkpoint capture/clear helpers, test getter, local-track-index getter |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_controls.dart` | Make `seekToPrevious()` attempt undo restore before normal player behavior |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_playback.dart` | Resolve and restore checkpoints without recursively creating a new one |
| Modify | `packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart` | Clear the checkpoint on app background and dispose timer/observer |
| Modify | `packages/shakedown_core/lib/ui/screens/show_list/show_list_logic_mixin.dart` | Capture undo before user-selected show/source/random/search jumps |
| Modify | `packages/shakedown_core/lib/ui/screens/track_list_screen.dart` | Capture undo before header-triggered playback |
| Modify | `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart` | Capture undo before user-selected track/show jumps |
| Modify | `packages/shakedown_core/lib/ui/screens/fruit_tab_host_screen.dart` | Capture undo before user-triggered random roll |
| Modify | `packages/shakedown_core/lib/ui/screens/rated_shows_screen.dart` | Capture undo before playing a rated show/source |
| Modify | `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart` | Capture undo before manual track taps |
| Modify | `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart` | Capture undo before Fruit track taps |
| Modify | `packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart` | Capture undo before TV random roll |
| Modify | `packages/shakedown_core/lib/ui/widgets/settings/usage_instructions_section.dart` | Add short help text describing the undo behavior |
| Create | `packages/shakedown_core/test/models/undo_checkpoint_test.dart` | Unit tests for expiry behavior |
| Modify | `packages/shakedown_core/test/providers/audio_provider_test.dart` | Provider tests for capture, restore, expiry, and lifecycle clearing |
| Create | `packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart` | Focused widget test for the help copy |

---

## Task 1: Add UndoCheckpoint and AudioProvider state scaffolding

**Files:**
- Create: `packages/shakedown_core/lib/models/undo_checkpoint.dart`
- Create: `packages/shakedown_core/test/models/undo_checkpoint_test.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_state.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart`

- [ ] **Step 1: Write the failing model test**

Create `packages/shakedown_core/test/models/undo_checkpoint_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/undo_checkpoint.dart';

void main() {
  group('UndoCheckpoint', () {
    test('isExpiredAt stays false through the 10 second window', () {
      final createdAt = DateTime(2026, 4, 7, 12, 0, 0);
      final checkpoint = UndoCheckpoint(
        sourceId: 'gd77-05-08.sbd.1234',
        showDate: '1977-05-08',
        trackIndex: 1,
        position: const Duration(seconds: 42),
        title: '1977-05-08 Barton Hall',
        createdAt: createdAt,
      );

      expect(
        checkpoint.isExpiredAt(createdAt.add(const Duration(seconds: 10))),
        isFalse,
      );
    });

    test('isExpiredAt becomes true after 10 seconds have passed', () {
      final createdAt = DateTime(2026, 4, 7, 12, 0, 0);
      final checkpoint = UndoCheckpoint(
        sourceId: 'gd77-05-08.sbd.1234',
        showDate: '1977-05-08',
        trackIndex: 1,
        position: const Duration(seconds: 42),
        title: '1977-05-08 Barton Hall',
        createdAt: createdAt,
      );

      expect(
        checkpoint.isExpiredAt(createdAt.add(const Duration(seconds: 11))),
        isTrue,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/models/undo_checkpoint_test.dart -v
```

Expected: FAIL with `Target of URI doesn't exist: 'package:shakedown_core/models/undo_checkpoint.dart'`.

- [ ] **Step 3: Add the UndoCheckpoint model**

Create `packages/shakedown_core/lib/models/undo_checkpoint.dart`:

```dart
class UndoCheckpoint {
  const UndoCheckpoint({
    required this.sourceId,
    required this.showDate,
    required this.trackIndex,
    required this.position,
    required this.title,
    required this.createdAt,
  });

  final String sourceId;
  final String showDate;
  final int trackIndex;
  final Duration position;
  final String title;
  final DateTime createdAt;

  bool isExpiredAt(
    DateTime now, {
    Duration maxAge = const Duration(seconds: 10),
  }) {
    return now.difference(createdAt) > maxAge;
  }
}
```

- [ ] **Step 4: Run the model test to verify it passes**

Run:

```bash
flutter test packages/shakedown_core/test/models/undo_checkpoint_test.dart -v
```

Expected: PASS.

- [ ] **Step 5: Add undo state to AudioProvider**

Update `packages/shakedown_core/lib/providers/audio_provider.dart`:

```dart
import 'dart:async';
import 'dart:math';
import 'dart:ui' show VoidCallback;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/models/dng_snapshot.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/undo_checkpoint.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/buffer_agent.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/random_show_selector.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/pwa_detection.dart';
import 'package:shakedown_core/utils/share_link_parser.dart';
import 'package:shakedown_core/utils/utils.dart';

part 'audio_provider_controls.dart';
part 'audio_provider_diagnostics.dart';
part 'audio_provider_lifecycle.dart';
part 'audio_provider_playback.dart';
part 'audio_provider_state.dart';

class AudioProvider extends ChangeNotifier
    with
        WidgetsBindingObserver,
        _AudioProviderState,
        _AudioProviderDiagnostics,
        _AudioProviderPlayback,
        _AudioProviderLifecycle,
        _AudioProviderControls {
  AudioProvider({
    GaplessPlayer? audioPlayer,
    CatalogService? catalogService,
    AudioCacheService? audioCacheService,
    WakelockService? wakelockService,
    bool useWebGaplessEngine = true,
    bool? isWeb,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _isWeb = isWeb ?? kIsWeb;
    _catalogService = catalogService ?? CatalogService();
    _audioCacheService = audioCacheService ?? AudioCacheService();
    _wakelockService = wakelockService ?? WakelockService();
    _audioPlayer = audioPlayer ?? GaplessPlayer();
    logger.i(
      'AudioProvider initialized with Engine: ${_audioPlayer.engineName}',
    );
    logger.i('Engine Selection Reason: ${_audioPlayer.selectionReason}');

    _listenForPlaybackProgress();
    _listenForErrors();
    _listenForProcessingState();

    _audioCacheService.addListener(notifyListeners);

    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((
      _,
    ) {
      final now = DateTime.now();
      if (now.difference(_lastBufferedNotify) <
          const Duration(milliseconds: 250)) {
        return;
      }
      _lastBufferedNotify = now;
      notifyListeners();
    });

    _audioPlayer.engineStateStringStream.listen((state) {
      if (state == 'suspended_by_os') {
        _setPlaybackResumePrompt(
          'Playback suspended by system. Tap play to resume.',
        );
      }
    });

    _audioPlayer.playBlockedStream.listen((_) {
      _setPlaybackResumePrompt(
        'Playback paused by browser. Tap play to resume.',
      );
    });

    _bufferAgentNotificationController.stream.listen((event) {
      _setAgentMessage(event.message);
    });

    _notificationController.stream.listen((message) {
      _setNotificationMessage(message);
    });
  }

  static Future<void> clearAudioCache() async {
    final service = AudioCacheService();
    unawaited(service.init());
    await service.clearAudioCache();
    service.dispose();
  }
}
```

Update `packages/shakedown_core/lib/providers/audio_provider_state.dart`:

```dart
part of 'audio_provider.dart';

mixin _AudioProviderState {
  late final GaplessPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  final _bufferAgentNotificationController =
      StreamController<
        ({String message, VoidCallback? retryAction})
      >.broadcast();
  final _notificationController = StreamController<String>.broadcast();
  final _playbackFocusRequestController = StreamController<void>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;
  bool? _lastPreventSleep;
  String? _lastTrackTransitionMode;
  int? _lastHandoffCrossfadeMs;
  bool? _lastOfflineBuffering;
  bool? _lastEnableBufferAgent;
  BufferAgent? _bufferAgent;

  Show? _currentShow;
  Source? _currentSource;
  ({Show show, Source source})? _pendingRandomShowRequest;

  bool _hasMarkedAsPlayed = false;
  UndoCheckpoint? _undoCheckpoint;
  Timer? _undoCheckpointTimer;
  bool _isRestoringUndo = false;

  String? _lastAgentMessage;
  String? _lastNotificationMessage;
  String? _lastIssueMessage;
  String? _playbackResumePromptMessage;
  DateTime? _lastIssueAt;
  Timer? _notificationTimeoutTimer;
  Timer? _issueTimeoutTimer;
  StreamController<DngSnapshot>? _diagnosticsController;
  Timer? _diagnosticsTimer;
  StreamController<HudSnapshot>? _hudSnapshotController;
  double? _lastKnownGapMs;

  bool _isTransitioning = false;
  bool _hasPrequeuedNextShow = false;
  bool _isSwitchingSource = false;
  int _playbackRequestSerial = 0;

  late final CatalogService _catalogService;
  late AudioCacheService _audioCacheService;
  late final WakelockService _wakelockService;
  StreamSubscription<Duration>? _bufferedPositionSubscription;
  DateTime _lastBufferedNotify = DateTime.fromMillisecondsSinceEpoch(0);

  String? _error;
  DateTime _lastErrorNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _fadeId = 0;
  late final bool _isWeb;

  GaplessPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  Show? get currentShow => _currentShow;
  Source? get currentSource => _currentSource;
  ({Show show, Source source})? get pendingRandomShowRequest =>
      _pendingRandomShowRequest;
  String? get error => _error;

  int get currentLocalTrackIndex {
    final index = _audioPlayer.currentIndex;
    if (index == null) return 0;
    final sequence = _audioPlayer.sequence;
    if (sequence.isEmpty || index >= sequence.length) return index;

    final sourceItem = sequence[index];
    if (sourceItem.tag is! MediaItem) return index;
    final item = sourceItem.tag as MediaItem;
    return item.extras?['track_index'] as int? ?? index;
  }

  Track? get currentTrack {
    if (_currentSource == null) return null;
    final localIndex = currentLocalTrackIndex;
    if (localIndex < 0 || localIndex >= _currentSource!.tracks.length) {
      return null;
    }
    return _currentSource!.tracks[localIndex];
  }

  void captureUndoCheckpoint() {
    if (_currentShow == null || _currentSource == null || _isRestoringUndo) {
      return;
    }

    _replaceUndoCheckpoint(
      UndoCheckpoint(
        sourceId: _currentSource!.id,
        showDate: _currentShow!.date,
        trackIndex: currentLocalTrackIndex,
        position: _audioPlayer.position,
        title: _currentShow!.name,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _replaceUndoCheckpoint(UndoCheckpoint checkpoint) {
    _undoCheckpointTimer?.cancel();
    _undoCheckpoint = checkpoint;
    _undoCheckpointTimer = Timer(
      const Duration(seconds: 10),
      _clearUndoCheckpoint,
    );
  }

  void _clearUndoCheckpoint() {
    _undoCheckpointTimer?.cancel();
    _undoCheckpointTimer = null;
    _undoCheckpoint = null;
  }

  @visibleForTesting
  UndoCheckpoint? get undoCheckpointForTest => _undoCheckpoint;

  Duration? get nextTrackBuffered => _audioPlayer.nextTrackBuffered;
  String get engineState => _audioPlayer.engineStateString;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get nextTrackBufferedStream =>
      _audioPlayer.nextTrackBufferedStream;
  Stream<Duration?> get nextTrackTotalStream =>
      _audioPlayer.nextTrackTotalStream;
  Stream<bool> get heartbeatActiveStream => _audioPlayer.heartbeatActiveStream;
  Stream<bool> get heartbeatNeededStream => _audioPlayer.heartbeatNeededStream;
  Stream<String> get engineStateStringStream =>
      _audioPlayer.engineStateStringStream;
  Stream<String> get engineContextStateStream =>
      _audioPlayer.engineContextStateStream;
  Stream<double> get driftStream => _audioPlayer.driftStream;
  Stream<String> get visibilityStream => _audioPlayer.visibilityStream;
  Stream<String> get playbackErrorStream => _errorController.stream;
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream =>
      _bufferAgentNotificationController.stream;
  Stream<String> get notificationStream => _notificationController.stream;
  Stream<void> get playbackFocusRequestStream =>
      _playbackFocusRequestController.stream;

  int get cachedTrackCount => _audioCacheService.cachedTrackCount;
}
```

Update `packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart`:

```dart
part of 'audio_provider.dart';

mixin _AudioProviderLifecycle
    on
        ChangeNotifier,
        _AudioProviderState,
        _AudioProviderPlayback,
        _AudioProviderDiagnostics {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _clearUndoCheckpoint();
    }
  }

  void _listenForProcessingState() {
    _processingStateSubscription = _audioPlayer.processingStateStream.listen((
      state,
    ) {
      _updateWakeLockState();

      if (state == ProcessingState.completed) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        final sequence = _audioPlayer.sequence;
        final currentIndex = _audioPlayer.currentIndex;
        final looksTerminal =
            sequence.isEmpty ||
            currentIndex == null ||
            currentIndex >= sequence.length - 1;
        logger.i(
          'AudioProvider: ProcessingState.completed received. AutoPlay: '
          '$shouldPlay, Transitioning: $_isTransitioning, Prequeued: '
          '$_hasPrequeuedNextShow, LooksTerminal: $looksTerminal',
        );
        if (!looksTerminal) {
          logger.w(
            'Ignoring ProcessingState.completed because player is not at the '
            'terminal index.',
          );
          return;
        }
        if (_isTransitioning || _hasPrequeuedNextShow) {
          logger.i(
            'Skipping fallback random show because a transition/prequeued '
            'show is already in flight.',
          );
          return;
        }
        if (shouldPlay) {
          logger.i('Playback completed. Triggering fallback random show...');
          playRandomShow();
        }
      }
    });

    _audioPlayer.playingStream.listen((isPlaying) {
      _updateWakeLockState();
      if (isPlaying) {
        _clearPlaybackResumePrompt();
      }
    });
  }

  Future<void> _updateWakeLockState() async {
    final shouldPreventScreensaver = _settingsProvider?.preventSleep ?? true;
    final isPlaying = _audioPlayer.playing;

    if (shouldPreventScreensaver && isPlaying) {
      try {
        if (!(await _wakelockService.enabled)) {
          await _wakelockService.enable();
          logger.d('AudioProvider: Wake Lock ENABLED (Prevent Sleep)');
        }
      } catch (e) {
        logger.w('Failed to enable Wake Lock: $e');
      }
    } else {
      try {
        if (await _wakelockService.enabled) {
          await _wakelockService.disable();
          logger.d('AudioProvider: Wake Lock DISABLED');
        }
      } catch (e) {
        logger.w('Failed to disable Wake Lock: $e');
      }
    }
  }

  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
    AudioCacheService audioCacheService,
  ) {
    _showListProvider = showListProvider;
    _audioCacheService = audioCacheService;

    if (_settingsProvider != null &&
        settingsProvider.webPrefetchSeconds !=
            _settingsProvider!.webPrefetchSeconds) {
      _audioPlayer.setWebPrefetchSeconds(settingsProvider.webPrefetchSeconds);
    }

    if (_settingsProvider != null &&
        settingsProvider.hybridHandoffMode !=
            _settingsProvider!.hybridHandoffMode) {
      _audioPlayer.setHybridHandoffMode(
        settingsProvider.hybridHandoffMode.name,
      );
    }

    if (_settingsProvider != null &&
        settingsProvider.hybridBackgroundMode !=
            _settingsProvider!.hybridBackgroundMode) {
      _audioPlayer.setHybridBackgroundMode(
        settingsProvider.hybridBackgroundMode.name,
      );
    }

    if (_settingsProvider == null ||
        settingsProvider.allowHiddenWebAudio !=
            _settingsProvider!.allowHiddenWebAudio) {
      _audioPlayer.setHybridAllowHiddenWebAudio(
        settingsProvider.allowHiddenWebAudio,
      );
    }

    if (_lastHandoffCrossfadeMs == null ||
        settingsProvider.handoffCrossfadeMs != _lastHandoffCrossfadeMs) {
      _audioPlayer.setHandoffCrossfadeMs(settingsProvider.handoffCrossfadeMs);
      _lastHandoffCrossfadeMs = settingsProvider.handoffCrossfadeMs;
    }

    if (_lastTrackTransitionMode == null ||
        settingsProvider.trackTransitionMode != _lastTrackTransitionMode) {
      _audioPlayer.setTrackTransitionMode(settingsProvider.trackTransitionMode);
      _lastTrackTransitionMode = settingsProvider.trackTransitionMode;
    }

    if (_lastPreventSleep == null ||
        settingsProvider.preventSleep != _lastPreventSleep) {
      _lastPreventSleep = settingsProvider.preventSleep;
      _updateWakeLockState();
    }

    _settingsProvider = settingsProvider;
    _updateBufferAgent();

    if (_lastOfflineBuffering == null ||
        _settingsProvider?.offlineBuffering != _lastOfflineBuffering) {
      _lastOfflineBuffering = _settingsProvider?.offlineBuffering;
      _audioCacheService.monitorCache(_lastOfflineBuffering ?? false);
    }
  }

  void _updateBufferAgent() {
    final shouldEnable = _settingsProvider?.enableBufferAgent ?? false;

    if (_lastEnableBufferAgent == shouldEnable) return;
    _lastEnableBufferAgent = shouldEnable;

    if (shouldEnable && _bufferAgent == null) {
      _bufferAgent = BufferAgent(
        _audioPlayer,
        onRecoveryNotification: (message, retryAction) {
          _bufferAgentNotificationController.add((
            message: message,
            retryAction: retryAction,
          ));
        },
      );
      logger.i('AudioProvider: Buffer Agent enabled');
    } else if (!shouldEnable && _bufferAgent != null) {
      _bufferAgent?.dispose();
      _bufferAgent = null;
      logger.i('AudioProvider: Buffer Agent disabled');
    }
  }

  void _listenForPlaybackProgress() {
    _indexSubscription = _audioPlayer.currentIndexStream.listen((index) async {
      final sequence = _audioPlayer.sequence;
      if (index == null || sequence.isEmpty) return;

      if (index == sequence.length - 1) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        if (!_isTransitioning && shouldPlay) {
          logger.i(
            'Started last track (Index $index, Length ${sequence.length}). '
            'Pre-queueing next random show...',
          );
          _isTransitioning = true;
          await queueRandomShow();
        } else {
          logger.d(
            'Last track reached (Index $index, Length ${sequence.length}), '
            'but skipping queue. Transitioning: $_isTransitioning, '
            'AutoPlay: $shouldPlay',
          );
        }
      }

      final currentSource = sequence[index];
      if (currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;

        if (sourceId != null &&
            _pendingRandomShowRequest != null &&
            _pendingRandomShowRequest!.source.id == sourceId) {
          _pendingRandomShowRequest = null;
        }

        if (sourceId != null && _currentSource?.id != sourceId) {
          if (_isSwitchingSource) {
            logger.d(
              'Ignoring source mismatch during manual switch (Player: '
              '$sourceId, App: ${_currentSource?.id})',
            );
          } else {
            _updateCurrentShowFromSourceId(sourceId);
          }
        }
      }

      notifyListeners();
    });
  }

  void _listenForErrors() {
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        logger.e('Playback error', error: error, stackTrace: stackTrace);
        _errorController.add('Playback error: $error');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _undoCheckpointTimer?.cancel();
    _audioCacheService.removeListener(notifyListeners);
    _processingStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _indexSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _errorController.close();
    _randomShowRequestController.close();
    _bufferAgentNotificationController.close();
    _notificationController.close();
    _playbackFocusRequestController.close();
    _diagnosticsTimer?.cancel();
    _diagnosticsController?.close();
    _hudSnapshotController?.close();
    _notificationTimeoutTimer?.cancel();
    _issueTimeoutTimer?.cancel();
    _audioPlayer.dispose();
    _wakelockService.disable();
    super.dispose();
  }
}
```

- [ ] **Step 6: Run focused tests to verify the scaffolding compiles**

Run:

```bash
flutter test packages/shakedown_core/test/models/undo_checkpoint_test.dart \
             packages/shakedown_core/test/providers/audio_provider_test.dart -v
```

Expected: `undo_checkpoint_test.dart` passes, `audio_provider_test.dart` still passes because `captureUndoCheckpoint()` is added but not consumed yet.

- [ ] **Step 7: Commit**

```bash
git add packages/shakedown_core/lib/models/undo_checkpoint.dart \
        packages/shakedown_core/test/models/undo_checkpoint_test.dart \
        packages/shakedown_core/lib/providers/audio_provider.dart \
        packages/shakedown_core/lib/providers/audio_provider_state.dart \
        packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart
git commit -m "feat(audio): add navigation undo checkpoint scaffolding"
```

---

## Task 2: Restore the undo checkpoint from Previous

**Files:**
- Modify: `packages/shakedown_core/lib/providers/audio_provider_controls.dart`
- Modify: `packages/shakedown_core/lib/providers/audio_provider_playback.dart`
- Modify: `packages/shakedown_core/test/providers/audio_provider_test.dart`

- [ ] **Step 1: Add failing provider tests**

Update `packages/shakedown_core/test/providers/audio_provider_test.dart` in two places.

First, loosen the existing `setAudioSources(...)` stub in `setUp()` so restore calls with `initialPosition` can be matched:

```dart
    when(
      mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      ),
    ).thenAnswer((_) async => const Duration(seconds: 100));
```

Then add this new group inside `group('AudioProvider Tests', () { ... })`:

```dart
    group('Navigation Undo', () {
      void primeSequence(Source source, {required int currentLocalIndex}) {
        when(mockAudioPlayer.currentIndex).thenReturn(currentLocalIndex);
        when(mockAudioPlayer.sequence).thenReturn(
          source.tracks.asMap().entries.map((entry) {
            return AudioSource.uri(
              Uri.parse(entry.value.url),
              tag: MediaItem(
                id: '${source.id}_${entry.key}',
                title: entry.value.title,
                extras: {
                  'source_id': source.id,
                  'track_index': entry.key,
                },
              ),
            );
          }).toList(),
        );
      }

      testWidgets('captureUndoCheckpoint stores current track and position', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first;

          await audioProvider.playSource(show, source);
          primeSequence(source, currentLocalIndex: 1);
          when(mockAudioPlayer.position).thenReturn(
            const Duration(seconds: 37),
          );

          audioProvider.captureUndoCheckpoint();

          final checkpoint = audioProvider.undoCheckpointForTest;
          expect(checkpoint, isNotNull);
          expect(checkpoint!.sourceId, source.id);
          expect(checkpoint.trackIndex, 1);
          expect(checkpoint.position, const Duration(seconds: 37));
        });
      });

      testWidgets(
        'seekToPrevious restores checkpoint when pressed near track start',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(mockAudioPlayer.position).thenReturn(
              const Duration(seconds: 28),
            );
            audioProvider.captureUndoCheckpoint();

            when(mockAudioPlayer.position).thenReturn(
              const Duration(seconds: 3),
            );

            await audioProvider.seekToPrevious();

            verify(
              mockAudioPlayer.setAudioSources(
                any,
                initialIndex: 0,
                initialPosition: const Duration(seconds: 28),
                preload: false,
              ),
            ).called(1);
            verifyNever(mockAudioPlayer.seekToPrevious());
            expect(audioProvider.undoCheckpointForTest, isNull);
          });
        },
      );

      testWidgets(
        'seekToPrevious delegates normally when current position is above threshold',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(mockAudioPlayer.position).thenReturn(
              const Duration(seconds: 28),
            );
            audioProvider.captureUndoCheckpoint();

            when(mockAudioPlayer.position).thenReturn(
              const Duration(seconds: 8),
            );

            await audioProvider.seekToPrevious();

            verify(mockAudioPlayer.seekToPrevious()).called(1);
          });
        },
      );

      testWidgets('checkpoint expires after 10 seconds', (
        WidgetTester tester,
      ) async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        await audioProvider.playSource(show, source);
        primeSequence(source, currentLocalIndex: 0);
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 12));
        audioProvider.captureUndoCheckpoint();

        await tester.pump(const Duration(seconds: 11));

        expect(audioProvider.undoCheckpointForTest, isNull);
      });

      testWidgets('paused lifecycle clears the checkpoint', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first;

          await audioProvider.playSource(show, source);
          primeSequence(source, currentLocalIndex: 0);
          when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 12));
          audioProvider.captureUndoCheckpoint();

          audioProvider.didChangeAppLifecycleState(AppLifecycleState.paused);

          expect(audioProvider.undoCheckpointForTest, isNull);
        });
      });
    });
```

- [ ] **Step 2: Run the provider tests to verify they fail**

Run:

```bash
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart \
  --plain-name "Navigation Undo" -v
```

Expected: FAIL because `seekToPrevious()` still delegates directly to the player and no restore helper exists yet.

- [ ] **Step 3: Implement restore-first Previous behavior**

Update `packages/shakedown_core/lib/providers/audio_provider_controls.dart`:

```dart
part of 'audio_provider.dart';

mixin _AudioProviderControls on ChangeNotifier, _AudioProviderState {
  Future<void> playSource(
    Show show,
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
  });

  Future<int> _fadeVolume({
    required double from,
    required double to,
    required Duration duration,
  }) async {
    _fadeId++;
    final currentFadeId = _fadeId;
    const steps = 15;
    final stepDurationMs = duration.inMilliseconds ~/ steps;
    final diff = to - from;

    if (stepDurationMs <= 0) {
      await _audioPlayer.setVolume(to);
      return currentFadeId;
    }

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDurationMs));
      if (_fadeId != currentFadeId) return currentFadeId;
      final volume = from + (diff * (i / steps));
      await _audioPlayer.setVolume(volume);
    }

    if (_fadeId == currentFadeId) {
      await _audioPlayer.setVolume(to);
    }
    return currentFadeId;
  }

  Future<void> play() async {
    try {
      if (_isWeb && (_settingsProvider?.usePlayPauseFade ?? true)) {
        await _audioPlayer.setVolume(0.0);
        unawaited(
          _audioPlayer.play().catchError((e, stack) {
            logger.e('AudioProvider: play() engine failed: $e');
          }),
        );
        await _fadeVolume(
          from: 0.0,
          to: 1.0,
          duration: const Duration(milliseconds: 150),
        );
        return;
      }

      await _audioPlayer.play();
    } catch (e) {
      logger.e('AudioProvider: play() failed: $e');
    }
  }

  Future<void> resume() => play();

  Future<void> pause() async {
    try {
      if (_isWeb && (_settingsProvider?.usePlayPauseFade ?? true)) {
        final fadeId = await _fadeVolume(
          from: 1.0,
          to: 0.0,
          duration: const Duration(milliseconds: 150),
        );

        if (_fadeId != fadeId) {
          logger.d('AudioProvider: pause() aborted; newer transition started.');
          return;
        }

        await _audioPlayer.pause();
        await _audioPlayer.setVolume(1.0);
        return;
      }

      await _audioPlayer.pause();
    } catch (e) {
      logger.e('AudioProvider: pause() failed: $e');
    }
  }

  Future<void> stop() => _audioPlayer.stop();

  Future<void> seekToNext() => _audioPlayer.seekToNext();

  Future<void> seekToPrevious() async {
    if (_audioPlayer.position <= const Duration(seconds: 5)) {
      final restored = await _restoreUndoCheckpointIfAvailable();
      if (restored) return;
    }
    await _audioPlayer.seekToPrevious();
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> retryCurrentSource() async {
    if (_currentShow == null || _currentSource == null) {
      logger.w('retryCurrentSource: No current show or source to retry.');
      return;
    }

    var localIndex = 0;
    if (_audioPlayer.currentIndex != null) {
      try {
        final sequence = _audioPlayer.sequence;
        if (sequence.isNotEmpty &&
            _audioPlayer.currentIndex! < sequence.length) {
          final currentItem =
              sequence[_audioPlayer.currentIndex!].tag as MediaItem;
          localIndex = currentItem.extras?['track_index'] as int? ?? 0;
        }
      } catch (e) {
        logger.w('retryCurrentSource: Error resolving local index: $e');
        localIndex = _audioPlayer.currentIndex!;
      }
    }

    logger.i(
      'retryCurrentSource: Retrying ${_currentShow!.name} at local index '
      '$localIndex',
    );
    await playSource(_currentShow!, _currentSource!, initialIndex: localIndex);
  }

  void seekToTrack(int localIndex) {
    if (_currentSource == null) return;

    final playerState = _audioPlayer.processingState;
    final isStuck =
        playerState == ProcessingState.loading ||
        playerState == ProcessingState.buffering;
    final sequence = _audioPlayer.sequence;

    if (isStuck &&
        (sequence.isEmpty || _audioPlayer.currentIndex != localIndex)) {
      logger.i(
        'seekToTrack: Player is stuck/loading. Re-triggering playSource at '
        'index $localIndex',
      );
      if (_currentShow != null) {
        unawaited(
          playSource(_currentShow!, _currentSource!, initialIndex: localIndex),
        );
        return;
      }
    }

    int? globalIndex;
    for (var i = 0; i < sequence.length; i++) {
      final source = sequence[i];
      if (source.tag is MediaItem) {
        final item = source.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;
        final trackIndex = item.extras?['track_index'] as int?;

        if (sourceId == _currentSource!.id && trackIndex == localIndex) {
          globalIndex = i;
          break;
        }
      }
    }

    if (globalIndex != null) {
      _audioPlayer.seek(Duration.zero, index: globalIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
      return;
    }

    try {
      _audioPlayer.seek(Duration.zero, index: localIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    } catch (e) {
      logger.e('seekToTrack fallback failed: $e');
      if (_currentShow != null) {
        unawaited(
          playSource(_currentShow!, _currentSource!, initialIndex: localIndex),
        );
      }
    }
  }
}
```

Update `packages/shakedown_core/lib/providers/audio_provider_playback.dart` by adding this helper after `playFromShareString(...)`:

```dart
  Future<bool> _restoreUndoCheckpointIfAvailable() async {
    final checkpoint = _undoCheckpoint;
    if (checkpoint == null || _showListProvider == null || _isRestoringUndo) {
      return false;
    }

    if (checkpoint.isExpiredAt(DateTime.now())) {
      _clearUndoCheckpoint();
      return false;
    }

    Show? targetShow;
    Source? targetSource;

    for (final show in _showListProvider!.allShows) {
      for (final source in show.sources) {
        if (source.id == checkpoint.sourceId) {
          targetShow = show;
          targetSource = source;
          break;
        }
      }
      if (targetSource != null) break;
    }

    if (targetShow == null || targetSource == null) {
      _clearUndoCheckpoint();
      return false;
    }

    if (!_showListProvider!.isSourceAllowed(targetSource)) {
      _clearUndoCheckpoint();
      return false;
    }

    _isRestoringUndo = true;
    try {
      await playSource(
        targetShow,
        targetSource,
        initialIndex: checkpoint.trackIndex,
        initialPosition: checkpoint.position,
      );
      _clearUndoCheckpoint();
      return true;
    } finally {
      _isRestoringUndo = false;
    }
  }
```

- [ ] **Step 4: Run the provider tests to verify they pass**

Run:

```bash
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart \
  --plain-name "Navigation Undo" -v
```

Expected: PASS.

- [ ] **Step 5: Run the full provider test file**

Run:

```bash
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart -v
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/providers/audio_provider_controls.dart \
        packages/shakedown_core/lib/providers/audio_provider_playback.dart \
        packages/shakedown_core/test/providers/audio_provider_test.dart
git commit -m "feat(audio): restore navigation undo from previous control"
```

---

## Task 3: Capture checkpoints from user actions and document the behavior

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/show_list/show_list_logic_mixin.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/fruit_tab_host_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/rated_shows_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/usage_instructions_section.dart`
- Create: `packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart`

- [ ] **Step 1: Add a failing help-copy test**

Create `packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/settings/usage_instructions_section.dart';

void main() {
  testWidgets('shows the navigation undo help text', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UsageInstructionsSection(
              scaleFactor: 1.0,
              initiallyExpanded: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Press Previous within the first 5 seconds to undo',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('This undo is temporary and expires after 10 seconds'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run the help-copy test to verify it fails**

Run:

```bash
flutter test \
  packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart -v
```

Expected: FAIL because the current `Player Controls` copy does not mention undo.

- [ ] **Step 3: Capture checkpoints before user-initiated navigation**

Apply these call-site changes.

Update `packages/shakedown_core/lib/ui/screens/show_list/show_list_logic_mixin.dart`:

```dart
  void _playSource(Show show, Source source) {
    unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final key = showListProvider.getShowKey(show);

    showListProvider.setLoadingShow(key);
    if (show.sources.length > 1 && showListProvider.expandedShowKey != key) {
      showListProvider.expandShow(key);
      animationController.forward(from: 0.0);
    }
    audioProvider.captureUndoCheckpoint();
    audioProvider.playSource(show, source);
    if (context.read<DeviceService>().isTv) {
      audioProvider.requestPlaybackFocus();
    }
  }
```

```dart
  Future<void> handlePlayRandomShow() async {
    unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.isChoosingRandomShow || isRandomShowLoading) {
      return;
    }

    if (audioProvider.pendingRandomShowRequest != null) {
      await audioProvider.playPendingSelection();
      return;
    }

    if (!showListProvider.hasUsedRandomButton) {
      showListProvider.markRandomButtonUsed();
    }

    if (showListProvider.expandedShowKey != null) {
      showListProvider.collapseCurrentShow();
      unawaited(animationController.reverse());
    }

    logger.d(
      'ShowListScreen: handlePlayRandomShow() - Triggering random show roll.',
    );
    showListProvider.setIsChoosingRandomShow(true);
    setState(() {
      lastRollStartTime = DateTime.now();
      isRandomShowLoading = true;
      isResettingRandomShow = false;
      userInitiatedRoll = true;
    });

    final isTv = context.read<DeviceService>().isTv;
    audioProvider.captureUndoCheckpoint();
    await audioProvider.playRandomShow(
      filterBySearch: true,
      delayPlayback: isTv,
    );
  }
```

```dart
  Future<bool> handleClipboardPlayback(
    String text, {
    required VoidCallback onSuccess,
  }) async {
    setState(() => showPasteFeedback = true);
    final audioProvider = context.read<AudioProvider>();
    audioProvider.captureUndoCheckpoint();
    final success = await audioProvider.playFromShareString(text);

    if (mounted) {
      if (success) {
        unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
        searchController.clear();
        searchFocusNode.unfocus();
        context.read<ShowListProvider>().setSearchVisible(false);
        setState(() => showPasteFeedback = false);

        final show = audioProvider.currentShow;
        final source = audioProvider.currentSource;
        if (show != null && source != null) {
          handleRandomShowSelection((show: show, source: source));
        }
        onSuccess();
      } else {
        setState(() => showPasteFeedback = false);
      }
    }
    return success;
  }
```

```dart
  void onSearchSubmitted(String text) {
    if (text.isEmpty) return;
    if (text.contains('https://archive.org/details/gd')) {
      handleClipboardPlayback(text, onSuccess: openPlaybackScreen);
      return;
    }

    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.filteredShows.isNotEmpty) {
      AppHaptics.selectionClick(context.read<DeviceService>());
      final topShow = showListProvider.filteredShows.first;
      if (topShow.sources.isNotEmpty) {
        final topSource = topShow.sources.first;
        audioProvider.captureUndoCheckpoint();
        audioProvider.playSource(topShow, topSource);
        handleRandomShowSelection((show: topShow, source: topSource));
        if (mounted && !context.read<DeviceService>().isTv) {
          openPlaybackScreen();
        }
        searchController.clear();
        searchFocusNode.unfocus();
      }
    }
  }
```

Update `packages/shakedown_core/lib/ui/screens/track_list_screen.dart`:

```dart
  Future<void> _playShowFromHeader({int initialIndex = 0}) async {
    unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
    final ap = context.read<AudioProvider>();
    ap.captureUndoCheckpoint();
    unawaited(
      ap.playSource(widget.show, widget.source, initialIndex: initialIndex),
    );
    await _openPlaybackScreen();
  }
```

Update `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`:

```dart
      if (audioProvider.currentSource?.id == source.id) {
        audioProvider.captureUndoCheckpoint();
        audioProvider.seekToTrack(index);
      } else {
        unawaited(_playShowFromHeader(initialIndex: index));
      }
```

Update `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart`:

```dart
                        onTap: () {
                          if (!isPlaying) {
                            AppHaptics.lightImpact(
                              context.read<DeviceService>(),
                            );
                            audioProvider.captureUndoCheckpoint();
                            audioProvider.seekToTrack(trackIndex);
                          }
                        },
```

```dart
                    onTap: () {
                      if (!isPlaying) {
                        AppHaptics.lightImpact(context.read<DeviceService>());
                        audioProvider.captureUndoCheckpoint();
                        audioProvider.seekToTrack(trackIndex);
                      }
                    },
```

```dart
          onTap: () {
            if (isPlaying) {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            } else {
              AppHaptics.lightImpact(context.read<DeviceService>());
              audioProvider.captureUndoCheckpoint();
              audioProvider.seekToTrack(trackIndex);
            }
          },
```

Update `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`:

```dart
    void activate() {
      AppHaptics.lightImpact(context.read<DeviceService>());
      widget.audioProvider.captureUndoCheckpoint();
      widget.audioProvider.seekToTrack(widget.index);
    }
```

Update `packages/shakedown_core/lib/ui/screens/rated_shows_screen.dart`:

```dart
          onLongPress: () {
            unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
            audioProvider.captureUndoCheckpoint();
            unawaited(audioProvider.playSource(show, source));
          },
```

Update `packages/shakedown_core/lib/ui/screens/fruit_tab_host_screen.dart`:

```dart
        debugPrint('Dice: Triggering playRandomShow...');
        audioProvider.captureUndoCheckpoint();
        final picked = await audioProvider.playRandomShow(delayPlayback: true);
```

Update `packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart`:

```dart
  void _onRandomPlay() {
    _focusLeftPane();
    final audioProvider = context.read<AudioProvider>();
    audioProvider.captureUndoCheckpoint();
    audioProvider.playRandomShow(animationOnly: true);
  }
```

- [ ] **Step 4: Add the usage note**

Update `packages/shakedown_core/lib/ui/widgets/settings/usage_instructions_section.dart` by replacing the existing `Player Controls` subtitle block:

```dart
            subtitle: Text.rich(
              TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12.0 * scaleFactor),
                children: const [
                  TextSpan(
                    text: 'Tap',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' the mini-player to open the full playback screen.\n',
                  ),
                  TextSpan(
                    text: 'Long-press',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' the mini-player to stop playback and clear the queue.\n',
                  ),
                  TextSpan(
                    text: 'Press Previous',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' within the first 5 seconds to undo an accidental track or show change and return to where you were.\n',
                  ),
                  TextSpan(
                    text: 'Note',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' this undo is temporary and expires after 10 seconds.',
                  ),
                ],
              ),
            ),
            isThreeLine: true,
```

- [ ] **Step 5: Run focused UI tests**

Run:

```bash
flutter test \
  packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart \
  packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart -v
```

Expected: PASS.

- [ ] **Step 6: Run the two highest-signal regression suites**

Run:

```bash
flutter test \
  packages/shakedown_core/test/providers/audio_provider_test.dart \
  packages/shakedown_core/test/ui/screens/settings_screen_test.dart -v
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/shakedown_core/lib/ui/screens/show_list/show_list_logic_mixin.dart \
        packages/shakedown_core/lib/ui/screens/track_list_screen.dart \
        packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart \
        packages/shakedown_core/lib/ui/screens/fruit_tab_host_screen.dart \
        packages/shakedown_core/lib/ui/screens/rated_shows_screen.dart \
        packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart \
        packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart \
        packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart \
        packages/shakedown_core/lib/ui/widgets/settings/usage_instructions_section.dart \
        packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart
git commit -m "feat(ui): capture navigation undo checkpoints from manual navigation"
```

---

## Spec Coverage Check

| Spec section | Covered by task |
|---|---|
| One in-memory undo checkpoint | Task 1 |
| No persistence on any platform | Task 1 (provider-only state) |
| Previous restores exact show/track/position | Task 2 |
| Restore only within first 5 seconds | Task 2 |
| Checkpoint expires after 10 seconds | Tasks 1-2 |
| Clear checkpoint on app background | Task 1 |
| Capture only for manual track/show/random navigation | Task 3 |
| Do not capture autoplay / transport next/previous | Task 2 uses restore-only `seekToPrevious()`, Task 3 limits capture to UI call sites |
| Help text in settings usage instructions | Task 3 |
| No visible history screen in v1 | Intentionally out of scope |
