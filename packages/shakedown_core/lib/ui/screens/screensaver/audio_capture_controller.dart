import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/ui/screens/screensaver/microphone_permission_flow.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/visualizer/audio_reactor_factory.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';

typedef PermissionFlowRunner =
    Future<T> Function<T>(Future<T> Function() action);

class ScreensaverAudioCaptureController {
  AudioReactor? audioReactor;
  int? debugAudioSessionId;

  bool _isInitializingAudioReactor = false;
  bool _isStereoCapturePending = false;
  bool _isStereoCaptureActive = false;
  bool _hasAttemptedStereoCapture = false;
  Timer? _sessionRetryTimer;
  int _sessionRetryCount = 0;

  static const int maxSessionRetries = 10;

  bool get isInitializingAudioReactor => _isInitializingAudioReactor;

  bool wantsStereoCapture(SettingsProvider settings) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (!settings.oilEnableAudioReactivity) {
      return false;
    }
    if (audioReactor is! VisualizerAudioReactor) {
      return false;
    }
    return settings.oilBeatDetectorMode == 'pcm';
  }

  Future<void> syncStereoCapture(
    SettingsProvider settings, {
    required bool allowPermissionPrompts,
    required PermissionFlowRunner runPermissionFlow,
    required bool mounted,
  }) async {
    final wantsCapture = wantsStereoCapture(settings);

    logger.i(
      'Screensaver: syncStereoCapture '
      '(wants=$wantsCapture, '
      'allowPermissionPrompts=$allowPermissionPrompts, '
      'audioReactivity=${settings.oilEnableAudioReactivity}, '
      'beatDetectorMode=${settings.oilBeatDetectorMode}, '
      'audioGraphMode=${settings.oilAudioGraphMode}, '
      'isStereoCaptureActive=$_isStereoCaptureActive, '
      'isStereoCapturePending=$_isStereoCapturePending, '
      'hasAttemptedStereoCapture=$_hasAttemptedStereoCapture)',
    );

    if (!wantsCapture) {
      logger.i('Screensaver: stereo capture not wanted, stopping/resetting');
      await stopStereoCapture(resetAttempt: true);
      return;
    }

    if (_isStereoCaptureActive ||
        _isStereoCapturePending ||
        _hasAttemptedStereoCapture) {
      logger.i(
        'Screensaver: stereo capture request skipped '
        '(active=$_isStereoCaptureActive, '
        'pending=$_isStereoCapturePending, '
        'attempted=$_hasAttemptedStereoCapture)',
      );
      return;
    }

    if (!allowPermissionPrompts) {
      logger.i(
        'Screensaver: Skipping enhanced capture request during '
        'non-interactive launch.',
      );
      return;
    }

    _isStereoCapturePending = true;
    _hasAttemptedStereoCapture = true;
    logger.i('Screensaver: requesting stereo capture permission');
    final started = await runPermissionFlow(
      () => VisualizerAudioReactor.requestStereoCapture().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.w('Screensaver: stereo capture request timed out');
          return false;
        },
      ),
    );
    _isStereoCapturePending = false;
    logger.i(
      'Screensaver: stereo capture request completed (started=$started)',
    );

    if (!started) {
      _hasAttemptedStereoCapture = false;
    }

    if (!mounted) {
      if (started) {
        await VisualizerAudioReactor.stopStereoCapture();
      }
      return;
    }

    _isStereoCaptureActive = started;
  }

  Future<void> stopStereoCapture({bool resetAttempt = false}) async {
    if (!_isStereoCaptureActive && !_isStereoCapturePending) {
      if (resetAttempt) {
        _hasAttemptedStereoCapture = false;
      }
      return;
    }
    _isStereoCapturePending = false;
    _isStereoCaptureActive = false;
    if (resetAttempt) {
      _hasAttemptedStereoCapture = false;
    }
    await VisualizerAudioReactor.stopStereoCapture();
  }

  Future<AudioReactor?> createStartedAudioReactor({
    required int? audioSessionId,
    required bool isTv,
  }) async {
    logger.i(
      'Screensaver: creating audio reactor '
      '(audioSessionId=$audioSessionId, isTv=$isTv)',
    );
    final reactor = await AudioReactorFactory.create(
      audioSessionId: audioSessionId,
      isTv: isTv,
    );
    if (reactor == null) {
      logger.w('Screensaver: audio reactor factory returned null');
      return null;
    }
    logger.i('Screensaver: audio reactor created (${reactor.runtimeType})');
    final started = await reactor.start();
    if (!started) {
      logger.w('Screensaver: audio reactor failed to start');
      reactor.dispose();
      return null;
    }
    logger.i('Screensaver: audio reactor started (${reactor.runtimeType})');
    return reactor;
  }

  Future<void> initAudioReactor({
    required SettingsProvider settings,
    required AudioProvider audioProvider,
    required bool isTv,
    required bool allowPermissionPrompts,
    required bool mounted,
    required MicrophonePermissionFlow permissionFlow,
    required VoidCallback clearPushedAudioConfig,
    required void Function(SettingsProvider settings) pushAudioConfig,
    required Future<void> Function({bool isRetry}) retryInitAudioReactor,
    required VoidCallback onAudioReactorChanged,
    bool isRetry = false,
  }) async {
    if (_isInitializingAudioReactor) return;
    if (audioReactor != null && !isRetry) return;
    _isInitializingAudioReactor = true;

    try {
      if (kIsWeb || !settings.oilEnableAudioReactivity) return;

      PermissionStatus? microphoneStatus;
      final deferMicrophonePermission = shouldDeferMicrophonePermission(
        targetPlatform: defaultTargetPlatform,
        isTv: isTv,
        beatDetectorMode: settings.oilBeatDetectorMode,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        microphoneStatus = await permissionFlow.getMicrophonePermissionStatus();
        if (microphoneStatus == null) {
          debugPrint(
            'Screensaver: Microphone permission state unavailable. '
            'Reactivity disabled for this session.',
          );
          return;
        }
        if (!deferMicrophonePermission && !microphoneStatus.isGranted) {
          if (!allowPermissionPrompts) {
            debugPrint(
              'Screensaver: Skipping microphone permission request during '
              'non-interactive launch. Reactivity disabled for this session.',
            );
            return;
          }
          microphoneStatus = await permissionFlow.requestMicrophonePermission();
          if (microphoneStatus?.isGranted != true) {
            debugPrint(
              'Screensaver: Audio permission denied. Reactivity disabled.',
            );
            return;
          }
        } else if (deferMicrophonePermission &&
            !allowPermissionPrompts &&
            !microphoneStatus.isGranted) {
          debugPrint(
            'Screensaver: Skipping deferred microphone permission request '
            'during non-interactive launch. Enhanced reactivity disabled '
            'for this session.',
          );
          return;
        }
      }

      int? sessionId;
      if (defaultTargetPlatform == TargetPlatform.android) {
        sessionId = audioProvider.audioPlayer.androidAudioSessionId;
        debugAudioSessionId = sessionId;
      }

      if ((sessionId == null || sessionId == 0) &&
          _sessionRetryCount < maxSessionRetries) {
        _sessionRetryCount++;
        debugPrint(
          'Screensaver: Session ID is $sessionId, scheduling retry '
          '$_sessionRetryCount/$maxSessionRetries',
        );
        _sessionRetryTimer?.cancel();
        _sessionRetryTimer = Timer(const Duration(seconds: 2), () {
          unawaited(retryInitAudioReactor(isRetry: true));
        });
        if (audioReactor != null) return;
      }

      if (isRetry && audioReactor != null) {
        audioReactor?.dispose();
        audioReactor = null;
        clearPushedAudioConfig();
        onAudioReactorChanged();
      }

      AudioReactor? reactor = await createStartedAudioReactor(
        audioSessionId: sessionId,
        isTv: isTv,
      );
      logger.i(
        'Screensaver: createStartedAudioReactor returned '
        '${reactor?.runtimeType ?? 'null'}',
      );

      if (reactor == null &&
          defaultTargetPlatform == TargetPlatform.android &&
          deferMicrophonePermission &&
          microphoneStatus != null &&
          !microphoneStatus.isGranted) {
        if (!allowPermissionPrompts) {
          debugPrint(
            'Screensaver: Skipping deferred microphone permission request '
            'during non-interactive launch. Enhanced reactivity disabled '
            'for this session.',
          );
          return;
        }
        microphoneStatus = await permissionFlow.requestMicrophonePermission();
        if (microphoneStatus?.isGranted != true) {
          debugPrint(
            'Screensaver: Audio permission denied. Reactivity disabled.',
          );
          return;
        }
        reactor = await createStartedAudioReactor(
          audioSessionId: sessionId,
          isTv: isTv,
        );
      }

      if (!mounted) {
        reactor?.dispose();
        return;
      }

      if (reactor == null) {
        debugPrint(
          'Screensaver: Audio reactor unavailable. Reactivity disabled '
          'for this session.',
        );
        return;
      }

      logger.i('Screensaver: storing audio reactor (${reactor.runtimeType})');
      audioReactor = reactor;
      onAudioReactorChanged();
      if (reactor is VisualizerAudioReactor) {
        logger.i('Screensaver: pushing audio config to VisualizerAudioReactor');
        pushAudioConfig(settings);
        logger.i('Screensaver: calling _syncStereoCapture');
        await syncStereoCapture(
          settings,
          allowPermissionPrompts: allowPermissionPrompts,
          runPermissionFlow: permissionFlow.runPermissionFlow,
          mounted: mounted,
        );
        logger.i('Screensaver: _syncStereoCapture completed');
      }
    } finally {
      _isInitializingAudioReactor = false;
    }
  }

  void dispose({required VoidCallback clearPushedAudioConfig}) {
    _sessionRetryTimer?.cancel();
    audioReactor?.dispose();
    audioReactor = null;
    clearPushedAudioConfig();
  }
}
