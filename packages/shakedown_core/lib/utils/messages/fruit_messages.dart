import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

OverlayEntry? _fruitMessageOverlay;
Timer? _fruitMessageTimer;

void showFruitMessageOverlay(
  BuildContext context,
  String message, {
  bool preferCenter = false,
  bool large = false,
  Alignment? preferredAlignment,
  VoidCallback? onMaterialFallback,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onMaterialFallback?.call();
    return;
  }

  removeFruitMessageOverlay();
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final useLiquidGlass = shouldUseFruitLiquidGlass(context);

  _fruitMessageOverlay = OverlayEntry(
    builder: (overlayContext) {
      final media = MediaQuery.maybeOf(overlayContext);
      final bottomInset = media?.viewInsets.bottom ?? 0;
      final safeBottom = media?.padding.bottom ?? 0;
      final overlayAlignment =
          preferredAlignment ??
          (preferCenter ? const Alignment(0, -0.12) : Alignment.bottomCenter);
      final overlayPadding = preferCenter
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
          : EdgeInsets.fromLTRB(16, 16, 16, 94 + safeBottom + bottomInset);

      return Positioned.fill(
        child: IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: overlayAlignment,
              child: Padding(
                padding: overlayPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: large ? 680 : 560,
                    minWidth: large ? 280 : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(large ? 22 : 18),
                    child: Builder(
                      builder: (context) {
                        final messageContent = Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: large ? 26 : 18,
                            vertical: large ? 18 : 14,
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
                                fontSize: large ? 24 : 14,
                                letterSpacing: 0.1,
                                color: colorScheme.onSurface,
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
                                    borderRadius: BorderRadius.circular(
                                      large ? 22 : 18,
                                    ),
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
                                  borderRadius: BorderRadius.circular(
                                    large ? 22 : 18,
                                  ),
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
    try {
      overlay.insert(overlayEntry);
      _fruitMessageTimer = Timer(const Duration(seconds: 3), () {
        removeFruitMessageOverlay();
      });
    } catch (_) {
      _fruitMessageOverlay = null;
      onMaterialFallback?.call();
    }
  }
}

void showFruitIssueOverlay(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  VoidCallback? onClear,
  VoidCallback? onMaterialFallback,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onMaterialFallback?.call();
    return;
  }

  removeFruitMessageOverlay();
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final useLiquidGlass = shouldUseFruitLiquidGlass(context);

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
                94 + safeBottom + bottomInset,
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
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (onAction != null && actionLabel != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  onAction();
                                  removeFruitMessageOverlay();
                                },
                                child: _FruitActionChip(label: actionLabel),
                              ),
                            ] else if (onClear != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  onClear();
                                  removeFruitMessageOverlay();
                                },
                                child: const _FruitActionChip(label: 'Clear'),
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

  try {
    overlay.insert(_fruitMessageOverlay!);
    _fruitMessageTimer?.cancel();
    _fruitMessageTimer = Timer(const Duration(seconds: 8), () {
      removeFruitMessageOverlay();
    });
  } catch (_) {
    _fruitMessageOverlay = null;
    onMaterialFallback?.call();
  }
}

void removeFruitMessageOverlay() {
  _fruitMessageTimer?.cancel();
  _fruitMessageTimer = null;
  try {
    _fruitMessageOverlay?.remove();
  } catch (_) {
    // Overlay host may already be gone (common during widget test teardown).
  }
  _fruitMessageOverlay = null;
}

bool shouldUseFruitLiquidGlass(BuildContext context) {
  try {
    final settings = context.read<SettingsProvider>();
    return settings.fruitEnableLiquidGlass &&
        !settings.performanceMode &&
        !isWasmSafeMode();
  } catch (_) {
    return false;
  }
}

class _FruitActionChip extends StatelessWidget {
  const _FruitActionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
