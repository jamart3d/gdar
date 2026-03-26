import 'dart:async';
import 'dart:math';
import 'dart:ui' show VoidCallback;

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/models/dng_snapshot.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
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
  }) {
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
        _setAgentMessage('Playback suspended by system. Tap play to resume.');
      }
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
