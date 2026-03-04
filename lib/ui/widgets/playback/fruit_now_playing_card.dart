import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();

    return NeumorphicWrapper(
      intensity: 0.8,
      borderRadius: 40.0 * scaleFactor, // rounded-[2.5rem]
      child: Container(
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
                  Icons.bar_chart_rounded, // Equalizer icon from mockup
                  color: colorScheme.primary,
                  size: 20 * scaleFactor,
                ),
              ],
            ),
            SizedBox(height: 32 * scaleFactor), // space-y-8 equivalent

            // Progress Bar
            _buildProgressBar(context, colorScheme, audioProvider),
            SizedBox(height: 32 * scaleFactor), // space-y-8 equivalent

            // Controls
            _buildControls(context, colorScheme, audioProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme colorScheme,
      AudioProvider audioProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return NeumorphicWrapper(
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
                      width: constraints.maxWidth * 0.35, // w-[35%] mockup
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.35 - (6 * scaleFactor),
                    top: -1 * scaleFactor,
                    child: Container(
                      width: 6 * scaleFactor,
                      height: 6 * scaleFactor,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
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
        SizedBox(height: 12 * scaleFactor),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2:45',
                style: _progressTextStyle(colorScheme)), // mockup values
            Text('8:14', style: _progressTextStyle(colorScheme)),
          ],
        ),
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
      AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        NeumorphicWrapper(
          intensity: 0.6,
          isCircle: true,
          child: InkWell(
            onTap: () => audioProvider.seekToPrevious(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56 * scaleFactor,
              height: 56 * scaleFactor,
              child: Center(
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 26 * scaleFactor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 32 * scaleFactor),
        // Play/Pause Button (Large)
        NeumorphicWrapper(
          intensity: 0.8,
          isCircle: true,
          child: InkWell(
            onTap: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72 * scaleFactor,
              height: 72 * scaleFactor,
              child: Center(
                child: Icon(
                  audioProvider.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: colorScheme.primary,
                  size: 36 * scaleFactor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 32 * scaleFactor),
        // Next Button
        NeumorphicWrapper(
          intensity: 0.6,
          isCircle: true,
          child: InkWell(
            onTap: () => audioProvider.seekToNext(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56 * scaleFactor,
              height: 56 * scaleFactor,
              child: Center(
                child: Icon(
                  Icons.skip_next_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 26 * scaleFactor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
