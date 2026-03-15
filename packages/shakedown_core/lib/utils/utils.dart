import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shakedown_core/utils/app_reload/app_reload.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

String? _lastSnackMessage;
DateTime? _lastSnackTime;
OverlayEntry? _fruitMessageOverlay;
Timer? _fruitMessageTimer;

String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

Duration parseDuration(String s) {
  try {
    final parts = s.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    }
  } catch (e) {
    logger.w('Error parsing duration: $s');
  }
  return Duration.zero;
}

String? transformArchiveUrl(String url) {
  // Replace 'download' with 'details'
  String newUrl = url.replaceFirst('/download/', '/details/');

  // Remove the filename (everything after the last slash)
  // But we need to be careful. The user said "chop off the late file".
  // The example shows removing the last segment.
  // "https://archive.org/details/identifier/filename.mp3" -> "https://archive.org/details/identifier/"

  final lastSlashIndex = newUrl.lastIndexOf('/');
  if (lastSlashIndex != -1) {
    newUrl = newUrl.substring(0, lastSlashIndex + 1);
  }

  return newUrl;
}

Future<void> launchArchivePage(
  String firstTrackUrl, [
  BuildContext? context,
]) async {
  // Example URL: "https://archive.org/download/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/07BirdSong.mp3"
  // Target URL: "https://archive.org/details/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/"

  try {
    final targetUrl = transformArchiveUrl(firstTrackUrl);
    if (targetUrl != null) {
      final uri = Uri.parse(targetUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $targetUrl');
      }
    }
  } catch (e) {
    logger.e('Error parsing URL or launching archive page: $e');
    if (context != null && context.mounted) {
      showMessage(context, 'Could not open browser: $e');
    }
  }
}

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
  } else {
    final now = DateTime.now();
    final isRapidDuplicate =
        _lastSnackMessage == message &&
        _lastSnackTime != null &&
        now.difference(_lastSnackTime!) < const Duration(milliseconds: 1500);
    if (isRapidDuplicate) return;

    _lastSnackMessage = message;
    _lastSnackTime = now;

    final bool isFruit = _isFruitTheme(context);
    if (isFruit) {
      _showFruitMessageOverlay(context, message);
      return;
    }

    _showMaterialSnackBar(context, message);
  }
}

void showRestartMessage(BuildContext context, String message) {
  if (!context.mounted) return;

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
    return;
  }

  final bool isFruit = _isFruitTheme(context);
  if (isFruit) {
    _showFruitIssueOverlay(
      context,
      message,
      actionLabel: 'Restart',
      onAction: () => restartApp(),
    );
    return;
  }

  _showMaterialSnackBarWithAction(
    context,
    message,
    actionLabel: 'Restart',
    onAction: () => restartApp(),
  );
}

// restartApp() is now imported from app_reload.dart

void showIssueMessage(
  BuildContext context,
  String message, {
  VoidCallback? onClear,
}) {
  if (!context.mounted) return;

  final isTv = context.read<DeviceService>().isTv;
  if (isTv) {
    context.read<AudioProvider>().showNotification(message);
    onClear?.call();
    return;
  }

  final bool isFruit = _isFruitTheme(context);
  if (isFruit) {
    _showFruitIssueOverlay(context, message, onClear: onClear);
    return;
  }

  _showMaterialSnackBarWithAction(
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

void _showMaterialSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}

void _showMaterialSnackBarWithAction(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.refresh_rounded,
            color: Theme.of(context).colorScheme.primaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 10),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    ),
  );
}

void _removeFruitMessageOverlay() {
  _fruitMessageTimer?.cancel();
  _fruitMessageTimer = null;
  _fruitMessageOverlay?.remove();
  _fruitMessageOverlay = null;
}

void _showFruitMessageOverlay(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    _showMaterialSnackBar(context, message);
    return;
  }

  _removeFruitMessageOverlay();
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool useLiquidGlass = _shouldUseFruitLiquidGlass(context);

  _fruitMessageOverlay = OverlayEntry(
    builder: (overlayContext) {
      final media = MediaQuery.maybeOf(overlayContext);
      final bottomInset = media?.viewInsets.bottom ?? 0;
      final safeBottom = media?.padding.bottom ?? 0;
      return Positioned.fill(
        child: IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  20 + safeBottom + bottomInset,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Builder(
                      builder: (context) {
                        final messageContent = Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Semantics(
                            liveRegion: true,
                            label: message,
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.1,
                                color: isDark
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );

                        return useLiquidGlass
                            ? BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 14,
                                  sigmaY: 14,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.45)
                                        : Colors.white.withValues(alpha: 0.58),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                      width: 0.8,
                                    ),
                                    boxShadow: isWasmSafeMode()
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.14,
                                              ),
                                              blurRadius: 22,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: messageContent,
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.surfaceContainerHigh
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: isDark ? 0.7 : 0.9),
                                    width: 0.8,
                                  ),
                                  boxShadow: isWasmSafeMode()
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: messageContent,
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  final overlayEntry = _fruitMessageOverlay;
  if (overlayEntry != null) {
    overlay.insert(overlayEntry);
    _fruitMessageTimer = Timer(const Duration(seconds: 3), () {
      _removeFruitMessageOverlay();
    });
  }
}

void _showFruitIssueOverlay(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  VoidCallback? onClear,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    _showMaterialSnackBarWithAction(
      context,
      message,
      actionLabel: 'Clear',
      onAction: onClear,
    );
    return;
  }

  _removeFruitMessageOverlay();
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool useLiquidGlass = _shouldUseFruitLiquidGlass(context);

  _fruitMessageOverlay = OverlayEntry(
    builder: (overlayContext) {
      final media = MediaQuery.maybeOf(overlayContext);
      final bottomInset = media?.viewInsets.bottom ?? 0;
      final safeBottom = media?.padding.bottom ?? 0;
      return Positioned.fill(
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                20 + safeBottom + bottomInset,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Builder(
                    builder: (context) {
                      final messageContent = Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.1,
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (onAction != null && actionLabel != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  onAction();
                                  _removeFruitMessageOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (onClear != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  onClear();
                                  _removeFruitMessageOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );

                      return useLiquidGlass
                          ? BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.58),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.65),
                                    width: 0.8,
                                  ),
                                  boxShadow: isWasmSafeMode()
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.14,
                                            ),
                                            blurRadius: 22,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: messageContent,
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? colorScheme.surfaceContainerHigh
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: isDark ? 0.7 : 0.9,
                                  ),
                                  width: 0.8,
                                ),
                                boxShadow: isWasmSafeMode()
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: messageContent,
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(_fruitMessageOverlay!);
  _fruitMessageTimer?.cancel();
  _fruitMessageTimer = Timer(const Duration(seconds: 8), () {
    _removeFruitMessageOverlay();
  });
}

bool _shouldUseFruitLiquidGlass(BuildContext context) {
  try {
    final settings = context.read<SettingsProvider>();
    return settings.fruitEnableLiquidGlass &&
        !settings.performanceMode &&
        !isWasmSafeMode();
  } catch (_) {
    return false;
  }
}

Future<void> launchArchiveDetails(
  String identifier, [
  BuildContext? context,
]) async {
  final detailsUrl = 'https://archive.org/details/$identifier';
  final detailsUri = Uri.parse(detailsUrl);

  try {
    if (!await launchUrl(detailsUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $detailsUrl');
    }
  } catch (e) {
    logger.e('Error launching archive details page: $e');
    if (context != null && context.mounted) {
      showMessage(context, 'Could not open browser: $e');
    }
  }
}
