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
  final Track track;
  final int index;
  final double scaleFactor;
  final bool showNext;

  const FruitNowPlayingCard({
    super.key,
    required this.trackShow,
    required this.track,
    required this.index,
    required this.scaleFactor,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final isSimple = settingsProvider.performanceMode;
    final showCompactHud = kIsWeb && settingsProvider.showDevAudioHud;
    final horizontalPadding = showCompactHud ? 12.0 : 16.0;

    return FruitSurface(
      borderRadius: BorderRadius.circular(16.0 * scaleFactor),
      blur: isSimple ? FruitTokens.blurSoft : 18.0,
      opacity: isSimple ? 0.96 : 0.78,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0 * scaleFactor),
          color: isSimple
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding * scaleFactor,
          vertical: 12.0 * scaleFactor,
        ),
        child: Row(
          children: [
            if (!showCompactHud) ...[
              _buildCompactPlayButton(context, audioProvider, colorScheme),
              SizedBox(width: 16 * scaleFactor),
            ],
            // Info & Progress
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.title,
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
                        const Flexible(
                          child: PlaybackMessages(
                            textAlign: TextAlign.left,
                            showDivider: false,
                            showDevHudInline: false,
                          ),
                        ),
                        SizedBox(width: 8 * scaleFactor),
                      ],
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
                          final buffered =
                              bufferedSnapshot.data ?? Duration.zero;
                          final progressBar = _buildCompactProgressBar(
                            audioProvider,
                            colorScheme,
                            isLoading: isLoading,
                            isBuffering: isBuffering,
                            bufferedPositionMs: buffered.inMilliseconds,
                            isSimple: isSimple,
                          );
                          if (!showCompactHud) return progressBar;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildCompactPlayButton(
                                    context,
                                    audioProvider,
                                    colorScheme,
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
        final bool isPending =
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;
        final bool isPlaying = playerState.playing;

        return Semantics(
          button: true,
          toggled: isPlaying,
          label: isPending
              ? 'Loading playback'
              : (isPlaying ? 'Pause playback' : 'Resume playback'),
          child: ExcludeSemantics(
            child: FocusableActionDetector(
              enabled: true,
              mouseCursor: SystemMouseCursors.click,
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
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
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _LiquidTransportGlyph(
                      isPlaying: isPlaying,
                      isPending: isPending,
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
  }

  Widget _buildDurationInfo(
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool isSimple,
  }) {
    final pos = audioProvider.audioPlayer.position;
    final dur = audioProvider.audioPlayer.duration ?? Duration.zero;
    final elapsed = formatDuration(pos);
    final total = formatDuration(dur);

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
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
            TextSpan(
              text: total,
              style: TextStyle(
                color: isSimple
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.88)
                    : colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProgressBar(
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool isLoading,
    required bool isBuffering,
    required int bufferedPositionMs,
    required bool isSimple,
  }) {
    final duration = audioProvider.audioPlayer.duration?.inMilliseconds ?? 0;
    final position = audioProvider.audioPlayer.position.inMilliseconds;
    final double progress = (duration > 0)
        ? (position / duration).clamp(0.0, 1.0)
        : 0.0;
    final double bufferedProgress = (duration > 0)
        ? (bufferedPositionMs / duration).clamp(0.0, 1.0)
        : 0.0;
    final bool hasKnownDuration = duration > 0;
    final bool showLoadingPulse = (isLoading || isBuffering) && !isSimple;

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
        if (!isLoading)
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
        if (isLoading && !hasKnownDuration)
          SizedBox(
            height: 3.0 * scaleFactor,
            width: double.infinity,
            child: isSimple
                ? Container(
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4 * scaleFactor),
                    ),
                  )
                : LinearProgressIndicator(
                    value: null,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.tertiary.withValues(alpha: 0.5),
                    ),
                  ),
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
        if (showLoadingPulse)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 6 * scaleFactor,
              height: 6 * scaleFactor,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLoading ? colorScheme.primary : colorScheme.tertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _LiquidTransportGlyph extends StatefulWidget {
  final bool isPlaying;
  final bool isPending;
  final Color color;
  final double size;

  const _LiquidTransportGlyph({
    required this.isPlaying,
    required this.isPending,
    required this.color,
    required this.size,
  });

  @override
  State<_LiquidTransportGlyph> createState() => _LiquidTransportGlyphState();
}

class _LiquidTransportGlyphState extends State<_LiquidTransportGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
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
                final shimmerX = ((t * 2.0) - 1.0) * (widget.size * 0.6);
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: widget.size * 0.9,
                        height: widget.size * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.14),
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
