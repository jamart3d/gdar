import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/track_list/track_list_actions.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/utils.dart';

class TrackListItemTile extends StatefulWidget {
  const TrackListItemTile({
    super.key,
    required this.track,
    required this.source,
    required this.index,
    required this.playShowFromHeader,
  });

  final Track track;
  final Source source;
  final int index;
  final Future<void> Function({required int initialIndex}) playShowFromHeader;

  @override
  State<TrackListItemTile> createState() => _TrackListItemTileState();
}

class _TrackListItemTileState extends State<TrackListItemTile> {
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (isFruit) {
      final audioProvider = context.watch<AudioProvider>();
      final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? -1;

      final isCurrentTrack =
          audioProvider.currentTrack != null &&
          audioProvider.currentTrack!.title == widget.track.title &&
          audioProvider.currentSource?.id == widget.source.id;

      final bool sameSource =
          audioProvider.currentSource?.id == widget.source.id;
      final isUpcoming = sameSource && widget.index > currentTrackIndex;
      final isNext = sameSource && widget.index == currentTrackIndex + 1;

      Color dotColor = colorScheme.primary;

      if (isCurrentTrack) {
        final processingState = audioProvider.audioPlayer.processingState;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          dotColor = const Color(0xFFFFA500);
        } else {
          dotColor = const Color(0xFF2E7D32);
        }
      } else if (isNext) {
        final nextBuffered = audioProvider.nextTrackBuffered;
        final engineState = audioProvider.engineState;

        if (nextBuffered != null && nextBuffered > Duration.zero) {
          dotColor = const Color(0xFF4CAF50);
        } else if (engineState == 'prefetching' || engineState == 'fetching') {
          dotColor = const Color(0xFFFFA500);
        }
      }

      final double contentOpacity = isUpcoming ? 0.6 : 1.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            setState(() => _tapPosition = details.globalPosition),
        onTap: () => handleTrackTap(
          context: context,
          source: widget.source,
          trackIndex: widget.index,
          settingsProvider: settingsProvider,
          audioProvider: audioProvider,
          colorScheme: colorScheme,
          tapPosition: _tapPosition,
          playShowFromHeader: widget.playShowFromHeader,
          togglePlayOnTap: settingsProvider.togglePlayOnTap,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Text(
                    widget.track.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentTrack
                          ? FontWeight.w900
                          : FontWeight.w700,
                      fontFamily: 'Inter',
                      color: isCurrentTrack
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: contentOpacity,
                child: Text(
                  Duration(
                    seconds: widget.track.duration,
                  ).toString().split('.').first.padLeft(8, '0').substring(3),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final titleStyle = AppTypography.body(
      context,
    ).copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.25);

    final durationStyle = AppTypography.tiny(context).copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final titleText = settingsProvider.showTrackNumbers
        ? '${widget.track.trackNumber}. ${widget.track.title}'
        : widget.track.title;

    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final audioProvider = context.watch<AudioProvider>();
    final isCurrentTrack =
        audioProvider.currentTrack != null &&
        audioProvider.currentTrack!.title == widget.track.title &&
        audioProvider.currentSource?.id == widget.source.id;
    final usePremium =
        settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    final Widget itemContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12 * scaleFactor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              titleText,
              style: titleStyle.copyWith(
                fontWeight: isCurrentTrack ? FontWeight.w900 : null,
                color: isCurrentTrack ? colorScheme.primary : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: settingsProvider.hideTrackDuration
                  ? TextAlign.center
                  : TextAlign.left,
            ),
          ),
          if (!settingsProvider.hideTrackDuration) ...[
            const SizedBox(width: 16),
            Text(
              formatDuration(Duration(seconds: widget.track.duration)),
              style: durationStyle,
            ),
          ],
        ],
      ),
    );

    if (context.read<DeviceService>().isTv) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TvFocusWrapper(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: itemContent,
        ),
      );
    }

    final Widget item = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTapDown: (details) =>
          setState(() => _tapPosition = details.globalPosition),
      onTap: () => handleTrackTap(
        context: context,
        source: widget.source,
        trackIndex: widget.index,
        settingsProvider: settingsProvider,
        audioProvider: audioProvider,
        colorScheme: colorScheme,
        tapPosition: _tapPosition,
        playShowFromHeader: widget.playShowFromHeader,
        togglePlayOnTap: settingsProvider.togglePlayOnTap,
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: itemContent,
      ),
    );

    if (usePremium && isCurrentTrack && !context.read<DeviceService>().isTv) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: NeumorphicWrapper(
          borderRadius: 16,
          intensity: 1.0,
          color: const Color(0x00000000),
          child: LiquidGlassWrapper(
            enabled: true,
            borderRadius: BorderRadius.circular(16),
            opacity: 0.08,
            blur: 10.0,
            child: item,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: item,
    );
  }
}
