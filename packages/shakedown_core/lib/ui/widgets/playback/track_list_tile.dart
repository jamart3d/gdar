import 'package:flutter/material.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_activity_indicator.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/utils.dart';

class TrackListTile extends StatelessWidget {
  const TrackListTile({
    super.key,
    required this.audioProvider,
    required this.track,
    required this.trackIndex,
    required this.isPlaying,
    required this.scaleFactor,
    this.activeTrackIndex,
    this.onTap,
    this.onLongPress,
  });

  final AudioProvider audioProvider;
  final Track track;
  final int trackIndex;
  final bool isPlaying;
  final double scaleFactor;
  final int? activeTrackIndex;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTv = context.read<DeviceService>().isTv;

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final titleFontSize = AppTypography.responsiveFontSize(
      context,
      isTv ? 14.0 : 16.0,
    );
    final titleColor = isFruit
        ? (isDarkMode
              ? Colors.white.withValues(alpha: isPlaying ? 1.0 : 0.9)
              : Colors.black.withValues(alpha: isPlaying ? 1.0 : 0.9))
        : (isPlaying ? colorScheme.primary : colorScheme.onSurface);
    final titleStyle = baseTitleStyle.copyWith(
      fontSize: titleFontSize,
      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w400,
      color: titleColor,
      height: 1.1,
      letterSpacing: isFruit ? -0.2 : null,
    );

    final leadingWidget = _buildLeadingWidget(
      context,
      isTv: isTv,
      isFruit: isFruit,
      isDarkMode: isDarkMode,
      titleColor: titleColor,
      colorScheme: colorScheme,
      settingsProvider: settingsProvider,
    );
    final durationStyle = _durationTextStyle(
      textTheme,
      colorScheme,
      scaleFactor,
      isFruit,
      isDarkMode,
    );
    final titleText = settingsProvider.showTrackNumbers
        ? '${track.trackNumber}. ${track.title}'
        : track.title;

    final listTile = isFruit
        ? _FruitTrackTile(
            leading: leadingWidget,
            title: titleText,
            titleStyle: titleStyle,
            trailing: settingsProvider.hideTrackDuration
                ? null
                : _buildDuration(
                    durationStyle,
                    settingsProvider,
                    isTv,
                    isPlaying,
                  ),
            onTap: isTv ? null : onTap,
            onLongPress: onLongPress,
            isTv: isTv,
            settingsProvider: settingsProvider,
          )
        : ListTile(
            leading: leadingWidget,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            visualDensity: isTv
                ? VisualDensity.compact
                : VisualDensity.standard,
            contentPadding: isTv
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: SizedBox(
              height:
                  titleStyle.fontSize! *
                  (settingsProvider.appFont == 'rock_salt' ? 2.0 : 1.6),
              child: ConditionalMarquee(
                text: titleText,
                style: titleStyle,
                textAlign: settingsProvider.hideTrackDuration
                    ? TextAlign.center
                    : TextAlign.start,
              ),
            ),
            trailing: settingsProvider.hideTrackDuration
                ? null
                : _buildDuration(
                    durationStyle,
                    settingsProvider,
                    isTv,
                    isPlaying,
                  ),
            onTap: isTv ? null : onTap,
            onLongPress: onLongPress,
          );

    if (isPlaying && isTv) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          listTile,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                width: double.infinity,
                child: StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = Duration(seconds: track.duration);
                    final progress = duration.inSeconds > 0
                        ? position.inSeconds / duration.inSeconds
                        : 0.0;

                    return StreamBuilder<Duration>(
                      stream: audioProvider.bufferedPositionStream,
                      builder: (context, buffSnapshot) {
                        final buffered = buffSnapshot.data ?? Duration.zero;
                        final bufferedProgress = duration.inSeconds > 0
                            ? buffered.inSeconds / duration.inSeconds
                            : 0.0;

                        return Stack(
                          children: [
                            Container(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: bufferedProgress.clamp(0.0, 1.0),
                              child: Container(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.tertiary,
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
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    return listTile;
  }

  Widget? _buildLeadingWidget(
    BuildContext context, {
    required bool isTv,
    required bool isFruit,
    required bool isDarkMode,
    required Color titleColor,
    required ColorScheme colorScheme,
    required SettingsProvider settingsProvider,
  }) {
    if (!isTv && !isFruit) return null;

    if (isPlaying) {
      return StreamBuilder<PlayerState>(
        stream: audioProvider.playerStateStream,
        builder: (context, snapshot) {
          final processingState = snapshot.data?.processingState;
          final playing = snapshot.data?.playing ?? false;

          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            return SizedBox(
              width: isFruit ? 32 : 24,
              height: isFruit ? 32 : 24,
              child: Center(
                child: isFruit
                    ? FruitActivityIndicator(radius: 10, color: titleColor)
                    : SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
            );
          }

          Widget icon = Icon(
            playing
                ? (isFruit ? LucideIcons.pause : Icons.pause_rounded)
                : (isFruit ? LucideIcons.play : Icons.play_arrow_rounded),
            color: isFruit ? titleColor : colorScheme.primary,
            size: isFruit ? 18 : 24,
          );

          if (isFruit) {
            icon = NeumorphicWrapper(
              enabled: settingsProvider.useNeumorphism,
              borderRadius: 20,
              isCircle: true,
              intensity: 0.8,
              child: LiquidGlassWrapper(
                enabled: !settingsProvider.useTrueBlack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: settingsProvider.useTrueBlack
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  child: icon,
                ),
              ),
            );
          }

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final deviceService = context.read<DeviceService>();
                AppHaptics.lightImpact(deviceService);
                if (playing) {
                  audioProvider.pause();
                } else {
                  audioProvider.audioPlayer.play();
                }
              },
              child: icon,
            ),
          );
        },
      );
    }

    if (!isFruit) {
      return const SizedBox(width: 24, height: 24);
    }

    final activeIdx =
        activeTrackIndex ?? audioProvider.audioPlayer.currentIndex ?? -1;
    final isPlayed = activeIdx >= 0 && trackIndex < activeIdx;
    final isNext = activeIdx >= 0 && trackIndex == activeIdx + 1;
    final Color dotColor;

    if (isPlayed) {
      dotColor = colorScheme.primary.withValues(alpha: 0.3);
    } else if (isNext) {
      final buffered = audioProvider.audioPlayer.nextTrackBuffered;
      final nextTotal = audioProvider.audioPlayer.nextTrackTotal;
      final hasBuffer = buffered != null && buffered.inMilliseconds > 0;
      final isFullyBuffered =
          hasBuffer &&
          nextTotal != null &&
          nextTotal.inMilliseconds > 0 &&
          buffered.inMilliseconds >= nextTotal.inMilliseconds - 500;
      dotColor = isFullyBuffered
          ? Colors.green
          : hasBuffer
          ? Colors.green.withValues(alpha: 0.6)
          : Colors.amber;
    } else {
      dotColor = isDarkMode
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.15);
    }

    return const SizedBox(
      width: 32,
      height: 32,
      child: Center(child: SizedBox.shrink()),
    ).copyWithDot(dotColor);
  }

  Widget? _buildDuration(
    TextStyle durationStyle,
    SettingsProvider settingsProvider,
    bool isTv,
    bool isCurrentlyPlaying,
  ) {
    if (settingsProvider.hideTrackDuration) return null;

    if (isCurrentlyPlaying && isTv) {
      return StreamBuilder<Duration>(
        stream: audioProvider.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          return Text(
            '${formatDuration(position)} / ${formatDuration(Duration(seconds: track.duration))}',
            style: durationStyle,
          );
        },
      );
    }

    return Text(
      formatDuration(Duration(seconds: track.duration)),
      style: durationStyle,
    );
  }
}

TextStyle _durationTextStyle(
  TextTheme textTheme,
  ColorScheme colorScheme,
  double scaleFactor, [
  bool isFruit = false,
  bool isDarkMode = true,
]) {
  final textColor = isFruit
      ? (isDarkMode
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.6))
      : colorScheme.onSurfaceVariant;

  return (textTheme.bodyMedium ?? const TextStyle())
      .apply(fontSizeFactor: scaleFactor)
      .copyWith(
        fontFamily: null,
        package: null,
        color: textColor,
        fontWeight: FontWeight.w500,
        letterSpacing: isFruit ? 0.3 : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      )
      .merge(TextStyle(fontFamily: FontConfig.resolve('Roboto')));
}

class _FruitTrackTile extends StatefulWidget {
  const _FruitTrackTile({
    this.leading,
    required this.title,
    required this.titleStyle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    required this.isTv,
    required this.settingsProvider,
  });

  final Widget? leading;
  final String title;
  final TextStyle titleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isTv;
  final SettingsProvider settingsProvider;

  @override
  State<_FruitTrackTile> createState() => _FruitTrackTileState();
}

class _FruitTrackTileState extends State<_FruitTrackTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isTv ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isTv ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.isTv
          ? null
          : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.6 : 1.0,
        child: Container(
          padding: widget.isTv
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height:
                      widget.titleStyle.fontSize! *
                      (widget.settingsProvider.appFont == 'rock_salt'
                          ? 2.0
                          : 1.6),
                  child: ConditionalMarquee(
                    text: widget.title,
                    style: widget.titleStyle,
                    textAlign: widget.settingsProvider.hideTrackDuration
                        ? TextAlign.center
                        : TextAlign.start,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on Widget {
  Widget copyWithDot(Color dotColor) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
      ),
    );
  }
}
