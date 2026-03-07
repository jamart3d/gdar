import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/ui/widgets/theme/fruit_icon_button.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';

class FruitNowPlayingCard extends StatelessWidget {
  final Show trackShow;
  final Track track;
  final int index;
  final double scaleFactor;

  const FruitNowPlayingCard({
    super.key,
    required this.trackShow,
    required this.track,
    required this.index,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return NeumorphicWrapper(
      enabled: settingsProvider.useNeumorphism,
      intensity: 0.8,
      borderRadius: 16.0 * scaleFactor,
      child: LiquidGlassWrapper(
        enabled: settingsProvider.fruitEnableLiquidGlass,
        borderRadius: BorderRadius.circular(16.0 * scaleFactor),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0 * scaleFactor),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.0 * scaleFactor,
            vertical: 12.0 * scaleFactor,
          ),
          child: Row(
            children: [
              // Play/Pause Button
              _buildCompactPlayButton(context, audioProvider, colorScheme),
              SizedBox(width: 16 * scaleFactor),
              // Info & Progress
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Dot Indicator - absolute start
                        Container(
                          width: 5 * scaleFactor,
                          height: 5 * scaleFactor,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10 * scaleFactor),
                        Expanded(
                          child: Text(
                            track.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        _buildDurationInfo(audioProvider, colorScheme),
                      ],
                    ),
                    SizedBox(height: 8 * scaleFactor),
                    _buildCompactProgressBar(audioProvider, colorScheme),
                  ],
                ),
              ),
              SizedBox(width: 12 * scaleFactor),
              // Skip Next Button (Compact)
              FruitIconButton(
                onPressed: () => audioProvider.seekToNext(),
                icon: Icon(
                  LucideIcons.skipForward,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 18 * scaleFactor,
                ),
                size: 20 * scaleFactor,
                padding: 4 * scaleFactor,
                tooltip: 'Skip Next',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPlayButton(BuildContext context,
      AudioProvider audioProvider, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        AppHaptics.lightImpact(context.read<DeviceService>());
        if (audioProvider.isPlaying) {
          audioProvider.pause();
        } else {
          audioProvider.resume();
        }
      },
      child: Container(
        width: 36 * scaleFactor,
        height: 36 * scaleFactor,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            audioProvider.isPlaying ? LucideIcons.pause : LucideIcons.play,
            size: 18 * scaleFactor,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInfo(
      AudioProvider audioProvider, ColorScheme colorScheme) {
    final pos = audioProvider.audioPlayer.position;
    final dur = audioProvider.audioPlayer.duration ?? Duration.zero;

    return Text(
      '${formatDuration(pos)} / ${formatDuration(dur)}',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10 * scaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildCompactProgressBar(
      AudioProvider audioProvider, ColorScheme colorScheme) {
    final duration = audioProvider.audioPlayer.duration?.inMilliseconds ?? 0;
    final position = audioProvider.audioPlayer.position.inMilliseconds;
    final double progress =
        (duration > 0) ? (position / duration).clamp(0.0, 1.0) : 0.0;

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
}
