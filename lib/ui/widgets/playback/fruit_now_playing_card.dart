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

    final showTrackNumbers = settingsProvider.showTrackNumbers;

    return NeumorphicWrapper(
      enabled: settingsProvider.useNeumorphism,
      intensity: 0.8,
      borderRadius: 40.0 * scaleFactor, // rounded-[2.5rem]
      child: LiquidGlassWrapper(
        enabled: settingsProvider.fruitEnableLiquidGlass,
        borderRadius: BorderRadius.circular(40.0 * scaleFactor),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40.0 * scaleFactor),
            boxShadow: [
              if (settingsProvider.useNeumorphism)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -5, // Inset-like effect
                ),
            ],
          ),
          padding: EdgeInsets.all(28.0 * scaleFactor), // p-7
          child: Column(
            children: [
              // Top Row: Track Num, Title, Equalizer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (showTrackNumbers) ...[
                          Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12 * scaleFactor, // text-xs
                              fontWeight: FontWeight.w900, // font-black
                              color: colorScheme.primary, // Blue in mockup
                            ),
                          ),
                          SizedBox(width: 16 * scaleFactor), // gap-4
                        ],
                        Expanded(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18 * scaleFactor, // text-lg
                              fontWeight: FontWeight.bold, // font-bold
                              height: 1.0, // leading-none
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.barChart, // Equalizer icon from mockup
                    color: colorScheme.primary,
                    size: 20 * scaleFactor,
                  ),
                ],
              ),
              SizedBox(height: 32 * scaleFactor), // space-y-8 equivalent
              // Progress Bar
              _buildProgressBar(
                  context, colorScheme, audioProvider, settingsProvider),
              SizedBox(height: 32 * scaleFactor), // space-y-8 equivalent
              // Controls
              _buildControls(
                  context, colorScheme, audioProvider, settingsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme colorScheme,
      AudioProvider audioProvider, SettingsProvider settingsProvider) {
    final hideDuration = settingsProvider.hideTrackDuration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final duration = audioProvider.audioPlayer.duration?.inSeconds ?? 0;
          final position = audioProvider.audioPlayer.position.inSeconds;
          final double progress = (duration > 0) ? (position / duration) : 0.0;

          return NeumorphicWrapper(
            enabled: settingsProvider.useNeumorphism,
            intensity: 0.4,
            borderRadius: 12.0 * scaleFactor,
            child: Container(
              height: 4.0 * scaleFactor, // h-1 (thinner)
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: constraints.maxWidth * progress,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth * progress) - (8 * scaleFactor),
                    top: -6 * scaleFactor,
                    child: Container(
                      width: 16 * scaleFactor,
                      height: 16 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2.5 * scaleFactor,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (!hideDuration) ...[
          SizedBox(height: 12 * scaleFactor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  formatDuration(Duration(
                      seconds: audioProvider.audioPlayer.position.inSeconds)),
                  style: _progressTextStyle(colorScheme)),
              Text(
                  formatDuration(Duration(
                      seconds:
                          audioProvider.audioPlayer.duration?.inSeconds ?? 0)),
                  style: _progressTextStyle(colorScheme)),
            ],
          ),
        ],
      ],
    );
  }

  TextStyle _progressTextStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 11 * scaleFactor,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme colorScheme,
      AudioProvider audioProvider, SettingsProvider settingsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        NeumorphicWrapper(
          enabled: settingsProvider.useNeumorphism,
          intensity: 0.6,
          isCircle: true,
          child: FruitIconButton(
            onPressed: () => audioProvider.seekToPrevious(),
            icon: Icon(
              LucideIcons.skipBack,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            size: 26 * scaleFactor,
            padding: 15 * scaleFactor, // Calculated to match 56x56
            tooltip: 'Skip Previous',
          ),
        ),
        SizedBox(width: 32 * scaleFactor),
        // Play/Pause Button (Large)
        NeumorphicWrapper(
          enabled: settingsProvider.useNeumorphism,
          intensity: 1.0,
          isCircle: true,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: FruitIconButton(
              onPressed: () {
                if (audioProvider.isPlaying) {
                  audioProvider.pause();
                } else {
                  audioProvider.resume();
                }
              },
              icon: Icon(
                audioProvider.isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: colorScheme.primary,
              ),
              size: 32 * scaleFactor,
              padding: 20 * scaleFactor, // Total 72x72
              tooltip: audioProvider.isPlaying ? 'Pause' : 'Play',
            ),
          ),
        ),
        SizedBox(width: 32 * scaleFactor),
        // Next Button
        NeumorphicWrapper(
          enabled: settingsProvider.useNeumorphism,
          intensity: 0.6,
          isCircle: true,
          child: FruitIconButton(
            onPressed: () => audioProvider.seekToNext(),
            icon: Icon(
              LucideIcons.skipForward,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            size: 26 * scaleFactor,
            padding: 15 * scaleFactor, // Calculated to match 56x56
            tooltip: 'Skip Next',
          ),
        ),
      ],
    );
  }
}
