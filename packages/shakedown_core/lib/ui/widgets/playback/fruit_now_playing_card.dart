import 'package:flutter/material.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/styles/font_config.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_messages.dart';
import 'package:just_audio/just_audio.dart';

class FruitNowPlayingCard extends StatelessWidget {
  final Show trackShow;
  final Track? track;
  final int index;
  final double scaleFactor;
  final bool showNext;

  const FruitNowPlayingCard({
    super.key,
    required this.trackShow,
    this.track,
    required this.index,
    required this.scaleFactor,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    final isSimple = context.select<SettingsProvider, bool>(
      (settings) => settings.performanceMode,
    );
    final enableLiquidGlass = context.select<SettingsProvider, bool>(
      (settings) => settings.fruitEnableLiquidGlass,
    );
    final showDevAudioHud = context.select<SettingsProvider, bool>(
      (settings) => settings.showDevAudioHud,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final hasGlass = enableLiquidGlass && !isSimple;
    final showCompactHud = kIsWeb && showDevAudioHud;
    final horizontalPadding = showCompactHud ? 12.0 : 16.0;

    return FruitSurface(
      borderRadius: BorderRadius.circular(16.0 * scaleFactor),
      blur: isSimple ? FruitTokens.blurSoft : 18.0,
      opacity: isSimple ? 0.96 : 0.88,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0 * scaleFactor),
          color: hasGlass
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.08)
              : colorScheme.surfaceContainer,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding * scaleFactor,
          vertical: 12.0 * scaleFactor,
        ),
        child: Row(
          children: [
            if (!showCompactHud) ...[
              _buildCompactPlayButton(
                context,
                audioProvider,
                colorScheme,
                enableLiquidGlass,
              ),
              SizedBox(width: 16 * scaleFactor),
            ],
            // Info & Progress
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                track?.title ?? 'Picking show...',
                                style: TextStyle(
                                  fontFamily: FontConfig.resolve('Inter'),
                                  fontSize: 15 * scaleFactor,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!showCompactHud) ...[
                              SizedBox(width: 8 * scaleFactor),
                              const PlaybackMessages(
                                textAlign: TextAlign.left,
                                showDivider: false,
                                showDevHudInline: false,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      _buildDurationInfo(
                        audioProvider,
                        colorScheme,
                        isSimple: isSimple,
                      ),
                      if (showCompactHud && showNext) ...[
                        SizedBox(width: 8 * scaleFactor),
                        _buildSkipNextButton(audioProvider, colorScheme),
                      ],
                    ],
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  StreamBuilder<PlayerState>(
                    stream: audioProvider.playerStateStream,
                    initialData: audioProvider.audioPlayer.playerState,
                    builder: (context, stateSnapshot) {
                      final processingState =
                          stateSnapshot.data?.processingState;
                      final isLoading =
                          processingState == ProcessingState.loading;
                      final isBuffering =
                          processingState == ProcessingState.buffering;
                      return StreamBuilder<Duration>(
                        stream: audioProvider.bufferedPositionStream,
                        initialData: audioProvider.audioPlayer.bufferedPosition,
                        builder: (context, bufferedSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: audioProvider.positionStream,
                            initialData: audioProvider.audioPlayer.position,
                            builder: (context, positionSnapshot) {
                              return StreamBuilder<Duration?>(
                                stream: audioProvider.durationStream,
                                initialData: audioProvider.audioPlayer.duration,
                                builder: (context, durationSnapshot) {
                                  final buffered =
                                      bufferedSnapshot.data ?? Duration.zero;
                                  final int positionMs =
                                      (positionSnapshot.data ?? Duration.zero)
                                          .inMilliseconds;
                                  final int durationMs =
                                      (durationSnapshot.data ?? Duration.zero)
                                          .inMilliseconds;
                                  final int bufferedMs =
                                      buffered.inMilliseconds;
                                  final progressBar = _buildCompactProgressBar(
                                    colorScheme,
                                    isLoading: isLoading,
                                    isBuffering: isBuffering,
                                    bufferedPositionMs: bufferedMs,
                                    positionMs: positionMs,
                                    durationMs: durationMs,
                                    glassEnabled: enableLiquidGlass,
                                  );
                                  if (!showCompactHud) return progressBar;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _buildCompactPlayButton(
                                            context,
                                            audioProvider,
                                            colorScheme,
                                            enableLiquidGlass,
                                          ),
                                          SizedBox(width: 6 * scaleFactor),
                                          Expanded(child: progressBar),
                                        ],
                                      ),
                                      SizedBox(height: 4 * scaleFactor),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: (36 + 18) * scaleFactor,
                                        ),
                                        child: const PlaybackMessages(
                                          textAlign: TextAlign.left,
                                          showDivider: false,
                                          showDevHudInline: false,
                                          fontScale: 0.74,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (showCompactHud) ...[
                    SizedBox(height: 8 * scaleFactor),
                    const PlaybackMessages(
                      textAlign: TextAlign.left,
                      showDivider: false,
                      showStatusLine: false,
                      compactDevHud: true,
                    ),
                  ],
                ],
              ),
            ),
            if (!showCompactHud && showNext) ...[
              SizedBox(width: 12 * scaleFactor),
              _buildSkipNextButton(audioProvider, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkipNextButton(
    AudioProvider audioProvider,
    ColorScheme colorScheme,
  ) {
    return FruitIconButton(
      onPressed: () => audioProvider.seekToNext(),
      icon: Icon(
        LucideIcons.skipForward,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 18 * scaleFactor,
      ),
      size: 20 * scaleFactor,
      padding: 4 * scaleFactor,
      tooltip: 'Skip Next',
    );
  }

  Widget _buildCompactPlayButton(
    BuildContext context,
    AudioProvider audioProvider,
    ColorScheme colorScheme,
    bool glassEnabled,
  ) {
    void activate() {
      AppHaptics.lightImpact(context.read<DeviceService>());
      if (audioProvider.isPlaying) {
        audioProvider.pause();
      } else {
        audioProvider.resume();
      }
    }

    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      initialData: audioProvider.audioPlayer.playerState,
      builder: (context, snapshot) {
        final playerState =
            snapshot.data ?? audioProvider.audioPlayer.playerState;
        final processingState = playerState.processingState;
        final bool isPlaying = playerState.playing;
        return StreamBuilder<Duration>(
          stream: audioProvider.bufferedPositionStream,
          initialData: audioProvider.audioPlayer.bufferedPosition,
          builder: (context, bufferedSnapshot) {
            return StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              initialData: audioProvider.audioPlayer.position,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: audioProvider.durationStream,
                  initialData: audioProvider.audioPlayer.duration,
                  builder: (context, durationSnapshot) {
                    final bool showPendingCue = _shouldShowPendingCue(
                      isLoading: processingState == ProcessingState.loading,
                      isBuffering: processingState == ProcessingState.buffering,
                      bufferedPositionMs:
                          (bufferedSnapshot.data ?? Duration.zero)
                              .inMilliseconds,
                      positionMs: (positionSnapshot.data ?? Duration.zero)
                          .inMilliseconds,
                      durationMs: (durationSnapshot.data ?? Duration.zero)
                          .inMilliseconds,
                    );

                    return Semantics(
                      button: true,
                      toggled: isPlaying,
                      label: showPendingCue
                          ? 'Loading playback'
                          : (isPlaying ? 'Pause playback' : 'Resume playback'),
                      child: ExcludeSemantics(
                        child: FocusableActionDetector(
                          enabled: true,
                          mouseCursor: SystemMouseCursors.click,
                          shortcuts: const <ShortcutActivator, Intent>{
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.space):
                                ActivateIntent(),
                          },
                          actions: <Type, Action<Intent>>{
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                activate();
                                return null;
                              },
                            ),
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: activate,
                            child: Container(
                              width: 36 * scaleFactor,
                              height: 36 * scaleFactor,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: isWasmSafeMode()
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _LiquidTransportGlyph(
                                  isPlaying: isPlaying,
                                  isPending: showPendingCue,
                                  glassEnabled: glassEnabled,
                                  color: colorScheme.onPrimary,
                                  size: 18 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDurationInfo(
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool isSimple,
  }) {
    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final pos = positionSnapshot.data ?? Duration.zero;
            final dur = durationSnapshot.data ?? Duration.zero;
            final isUnknown =
                dur.inMilliseconds == 0 && pos.inMilliseconds == 0;
            final elapsed = isUnknown ? '--:--' : formatDuration(pos);
            final total = isUnknown ? '--:--' : formatDuration(dur);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scaleFactor,
                vertical: 2 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: isSimple
                    ? colorScheme.onSurface.withValues(alpha: 0.06)
                    : colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6 * scaleFactor),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(
                      text: elapsed,
                      style: TextStyle(
                        color: isSimple
                            ? colorScheme.onSurface.withValues(alpha: 0.92)
                            : colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: total,
                      style: TextStyle(
                        color: isSimple
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.88,
                              )
                            : colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactProgressBar(
    ColorScheme colorScheme, {
    required bool isLoading,
    required bool isBuffering,
    required int bufferedPositionMs,
    required int positionMs,
    required int durationMs,
    required bool glassEnabled,
  }) {
    final duration = durationMs;
    final position = positionMs;
    final double progress = (duration > 0)
        ? (position / duration).clamp(0.0, 1.0)
        : 0.0;
    final double bufferedProgress = (duration > 0)
        ? (bufferedPositionMs / duration).clamp(0.0, 1.0)
        : 0.0;
    final bool showPendingState = _shouldShowPendingCue(
      isLoading: isLoading,
      isBuffering: isBuffering,
      bufferedPositionMs: bufferedPositionMs,
      positionMs: positionMs,
      durationMs: durationMs,
    );

    return Stack(
      children: [
        Container(
          height: 3.0 * scaleFactor,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4 * scaleFactor),
          ),
        ),
        if (bufferedProgress > 0)
          FractionallySizedBox(
            widthFactor: bufferedProgress,
            child: Container(
              height: 3.0 * scaleFactor,
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4 * scaleFactor),
              ),
            ),
          ),
        if (showPendingState)
          _FruitPendingProgressOverlay(
            key: const Key('fruit_pending_progress_overlay'),
            colorScheme: colorScheme,
            scaleFactor: scaleFactor,
            glassEnabled: glassEnabled,
            isLoading: isLoading,
          ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 3.0 * scaleFactor,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4 * scaleFactor),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowPendingCue({
    required bool isLoading,
    required bool isBuffering,
    required int bufferedPositionMs,
    required int positionMs,
    required int durationMs,
  }) {
    final int remainingMs = durationMs - positionMs;
    final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
    final bool hasVisibleBufferHeadroom =
        bufferedPositionMs > (positionMs + 350);
    return isLoading ||
        isBuffering ||
        (hasPlayableTail && !hasVisibleBufferHeadroom);
  }
}

class _FruitPendingProgressOverlay extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool glassEnabled;
  final bool isLoading;

  const _FruitPendingProgressOverlay({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.glassEnabled,
    required this.isLoading,
  });

  @override
  State<_FruitPendingProgressOverlay> createState() =>
      _FruitPendingProgressOverlayState();
}

class _FruitPendingProgressOverlayState
    extends State<_FruitPendingProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double barHeight = 4.0 * widget.scaleFactor;
    final BorderRadius borderRadius = BorderRadius.circular(
      4 * widget.scaleFactor,
    );
    final Color sweepColor = widget.isLoading
        ? widget.colorScheme.primary
        : widget.colorScheme.tertiary;

    return RepaintBoundary(
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double travel = _controller.value;
                final double pulse = 1.0 - ((travel - 0.5).abs() * 2.0);
                final double sweepWidth =
                    (widget.glassEnabled ? 84.0 : 66.0) * widget.scaleFactor;
                final double sweepLeft =
                    -sweepWidth +
                    ((constraints.maxWidth + (sweepWidth * 2.0)) * travel);
                final double beadLeft =
                    sweepLeft +
                    (sweepWidth * (widget.glassEnabled ? 0.76 : 0.72));
                final double baseAlpha = widget.glassEnabled ? 0.18 : 0.24;
                final double sweepAlpha = widget.glassEnabled ? 0.76 : 0.92;
                final double coreAlpha = widget.glassEnabled ? 0.44 : 0.60;
                final double haloAlpha = widget.glassEnabled ? 0.32 : 0.26;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      widget.colorScheme.primary.withValues(
                                        alpha: baseAlpha,
                                      ),
                                      widget.colorScheme.tertiary.withValues(
                                        alpha: baseAlpha * 0.96,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: sweepLeft,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      sweepColor.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: coreAlpha),
                                      sweepColor.withValues(alpha: sweepAlpha),
                                      Colors.white.withValues(alpha: coreAlpha),
                                      sweepColor.withValues(alpha: 0.0),
                                      Colors.transparent,
                                    ],
                                    stops: const [
                                      0.0,
                                      0.12,
                                      0.28,
                                      0.5,
                                      0.72,
                                      0.88,
                                      1.0,
                                    ],
                                  ),
                                ),
                                child: SizedBox(
                                  width: sweepWidth,
                                  height: barHeight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: beadLeft,
                      top: -1.5 * widget.scaleFactor,
                      child: Transform.scale(
                        scale: 0.92 + (pulse * 0.24),
                        child: Container(
                          width: 10.0 * widget.scaleFactor,
                          height: 7.0 * widget.scaleFactor,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              999 * widget.scaleFactor,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                sweepColor.withValues(alpha: 0.96),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sweepColor.withValues(alpha: haloAlpha),
                                blurRadius: widget.glassEnabled ? 14 : 9,
                                spreadRadius:
                                    (widget.glassEnabled ? 1.8 : 1.0) * pulse,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LiquidTransportGlyph extends StatefulWidget {
  final bool isPlaying;
  final bool isPending;
  final bool glassEnabled;
  final Color color;
  final double size;

  const _LiquidTransportGlyph({
    required this.isPlaying,
    required this.isPending,
    required this.glassEnabled,
    required this.color,
    required this.size,
  });

  @override
  State<_LiquidTransportGlyph> createState() => _LiquidTransportGlyphState();
}

class _LiquidTransportGlyphState extends State<_LiquidTransportGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.isPending) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LiquidTransportGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isPending && _shimmerController.isAnimating) {
      _shimmerController.stop();
      _shimmerController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = widget.isPlaying ? LucideIcons.pause : LucideIcons.play;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(
          begin: widget.isPending ? 0.72 : 0.9,
          end: 1.0,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: widget.isPending
          ? AnimatedBuilder(
              key: const ValueKey('pending'),
              animation: _shimmerController,
              builder: (context, _) {
                final t = _shimmerController.value;
                final pulse = 1.0 - ((t - 0.5).abs() * 2.0);
                final shimmerX = ((t * 2.0) - 1.0) * (widget.size * 0.6);
                return SizedBox(
                  key: const Key('fruit_pending_transport_halo'),
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.92 + (pulse * 0.18),
                        child: Container(
                          width: widget.size * 1.04,
                          height: widget.size * 1.04,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.color.withValues(
                                  alpha: widget.glassEnabled ? 0.26 : 0.20,
                                ),
                                widget.color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: widget.size * 0.9,
                        height: widget.size * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(
                            alpha: widget.glassEnabled ? 0.18 : 0.14,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: widget.glassEnabled ? 0.18 : 0.12,
                              ),
                              blurRadius: widget.glassEnabled ? 10 : 6,
                              spreadRadius: pulse * 0.8,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: widget.size * 0.48,
                        height: widget.size * 0.48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.88),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(shimmerX, 0),
                        child: Transform.rotate(
                          angle: -0.35,
                          child: Container(
                            width: widget.size * 0.22,
                            height: widget.size * 0.92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.size),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  widget.color.withValues(alpha: 0.0),
                                  widget.color.withValues(alpha: 0.95),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.2, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : Icon(
              key: ValueKey<String>('icon-$iconData'),
              iconData,
              size: widget.size,
              color: widget.color,
            ),
    );
  }
}
