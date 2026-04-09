import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_reload/app_reload.dart';
import 'package:shakedown_core/utils/duration_format.dart' as duration_format;
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/messages/fruit_messages.dart';
import 'package:shakedown_core/utils/messages/material_messages.dart';
import 'package:shakedown_core/utils/url_launcher_helpers.dart';

export 'package:shakedown_core/utils/duration_format.dart';
export 'package:shakedown_core/utils/url_launcher_helpers.dart'
    show transformArchiveUrl;

String? _lastSnackMessage;
DateTime? _lastSnackTime;

String formatDuration(Duration duration) =>
    duration_format.formatDuration(duration);

Duration parseDuration(String value) => duration_format.parseDuration(value);

Future<void> launchArchivePage(
  String firstTrackUrl, [
  BuildContext? context,
]) async {
  await openArchivePage(
    firstTrackUrl,
    onError: (error) {
      logger.e('Error parsing URL or launching archive page: $error');
      if (context != null && context.mounted) {
        showMessage(context, 'Could not open browser: $error');
      }
    },
  );
}

Future<void> launchArchiveDetails(
  String identifier, [
  BuildContext? context,
]) async {
  await openArchiveDetails(
    identifier,
    onError: (error) {
      logger.e('Error launching archive details page: $error');
      if (context != null && context.mounted) {
        showMessage(context, 'Could not open browser: $error');
      }
    },
  );
}

void showMessage(
  BuildContext context,
  String message, {
  bool preferCenter = false,
  bool large = false,
  Alignment? preferredAlignment,
}) {
  if (!context.mounted) {
    return;
  }

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
    return;
  }

  final now = DateTime.now();
  final isRapidDuplicate =
      _lastSnackMessage == message &&
      _lastSnackTime != null &&
      now.difference(_lastSnackTime!) < const Duration(milliseconds: 1500);
  if (isRapidDuplicate) {
    return;
  }

  _lastSnackMessage = message;
  _lastSnackTime = now;

  if (_isFruitTheme(context)) {
    showFruitMessageOverlay(
      context,
      message,
      preferCenter: preferCenter,
      large: large,
      preferredAlignment: preferredAlignment,
      onMaterialFallback: () => showMaterialSnackBar(context, message),
    );
    return;
  }

  showMaterialSnackBar(context, message);
}

void showRestartMessage(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
    return;
  }

  void saveAndRestart() {
    _savePlaybackSessionBeforeRestart(context);
    restartApp();
  }

  if (_isFruitTheme(context)) {
    showFruitIssueOverlay(
      context,
      message,
      actionLabel: 'Restart',
      onAction: saveAndRestart,
      onMaterialFallback: () => showMaterialSnackBarWithAction(
        context,
        message,
        actionLabel: 'Restart',
        onAction: saveAndRestart,
      ),
    );
    return;
  }

  showMaterialSnackBarWithAction(
    context,
    message,
    actionLabel: 'Restart',
    onAction: saveAndRestart,
  );
}

void showIssueMessage(
  BuildContext context,
  String message, {
  VoidCallback? onClear,
}) {
  if (!context.mounted) {
    return;
  }

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
    onClear?.call();
    return;
  }

  if (_isFruitTheme(context)) {
    showFruitIssueOverlay(
      context,
      message,
      onClear: onClear,
      onMaterialFallback: () => showMaterialSnackBarWithAction(
        context,
        message,
        actionLabel: 'Clear',
        onAction: onClear,
      ),
    );
    return;
  }

  showMaterialSnackBarWithAction(
    context,
    message,
    actionLabel: 'Clear',
    onAction: onClear,
  );
}

bool _isFruitTheme(BuildContext context) {
  try {
    return context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
  } catch (_) {
    return false;
  }
}

void _savePlaybackSessionBeforeRestart(BuildContext context) {
  try {
    final audio = context.read<AudioProvider>();
    final settings = context.read<SettingsProvider>();
    final sourceId = audio.currentSource?.id;
    if (sourceId == null) {
      return;
    }

    final player = audio.audioPlayer;
    final index = player.currentIndex;
    final sequence = player.sequence;
    if (index == null || index < 0 || index >= sequence.length) {
      return;
    }

    var localIndex = index;
    final tag = sequence[index].tag;
    if (tag is MediaItem) {
      localIndex = (tag.extras?['track_index'] as int?) ?? index;
    }

    final positionMs = player.position.inMilliseconds;
    settings.saveResumeSession(sourceId, localIndex, positionMs);
    logger.i(
      'Saved resume session: source=$sourceId, '
      'track=$localIndex, pos=${positionMs}ms',
    );
  } catch (error) {
    logger.w('Failed to save resume session: $error');
  }
}
