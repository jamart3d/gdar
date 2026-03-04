import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
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
    final isPlaying = audioProvider.isPlaying;

    return NeumorphicWrapper(
      intensity: 0.8,
      borderRadius: 40.0 * scaleFactor, // rounded-[2.5rem]
      child: Container(
        padding: EdgeInsets.all(24.0 * scaleFactor), // p-6
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
                          color: colorScheme.primary
                              .withValues(alpha: 0.4), // text-primary/40
                        ),
                      ),
                      SizedBox(width: 16 * scaleFactor), // gap-4
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
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
                            SizedBox(height: 4 * scaleFactor), // mt-1
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10 * scaleFactor, // text-[10px]
                                fontWeight: FontWeight.bold, // font-bold
                                letterSpacing: 2.0, // tracking-widest
                                color: colorScheme.primary, // text-primary
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Equalizer Pulse (Placeholder for now)
                _buildEqualizerPulse(context, colorScheme, isPlaying),
              ],
            ),
            SizedBox(height: 24 * scaleFactor), // space-y-6 equivalent

            // Progress Bar
            _buildProgressBar(context, colorScheme, audioProvider),
            SizedBox(height: 24 * scaleFactor), // space-y-6 equivalent

            // Controls (Liquid Glass)
            _buildControls(context, colorScheme, audioProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualizerPulse(
      BuildContext context, ColorScheme colorScheme, bool isPlaying) {
    if (!isPlaying) return const SizedBox.shrink();

    // In a real implementation this would use AnimationController
    // Providing static UI here matching HTML structure
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
            width: 4 * scaleFactor,
            height: 12 * scaleFactor,
            decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4))),
        SizedBox(width: 4 * scaleFactor),
        Container(
            width: 4 * scaleFactor,
            height: 20 * scaleFactor,
            decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4))),
        SizedBox(width: 4 * scaleFactor),
        Container(
            width: 4 * scaleFactor,
            height: 8 * scaleFactor,
            decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4))),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, ColorScheme colorScheme,
      AudioProvider audioProvider) {
    // We use a simplified version, as audioProvider might not have position info easily synchronous.
    // Stream building goes here in the real version, but we stick to the HTML design for the UI shell.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return NeumorphicWrapper(
            intensity: 0.5,
            borderRadius: 12.0 * scaleFactor,
            child: Container(
              height: 6.0 * scaleFactor, // h-1.5
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              child: Align(
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
            ),
          );
        }),
        SizedBox(height: 8 * scaleFactor), // space-y-2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0:00', style: _progressTextStyle(colorScheme)), // mock
            Text('0:00', style: _progressTextStyle(colorScheme)), // mock
          ],
        ),
      ],
    );
  }

  TextStyle _progressTextStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 10 * scaleFactor,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5, // tracking-tighter
      color: colorScheme.onSurfaceVariant
          .withValues(alpha: 0.6), // text-slate-400 equivalent
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme colorScheme,
      AudioProvider audioProvider) {
    final settingsProvider = context.read<SettingsProvider>();
    return LiquidGlassWrapper(
      enabled: settingsProvider.useNeumorphism,
      blur: 20.0,
      opacity: 0.3,
      borderRadius: BorderRadius.circular(24 * scaleFactor), // rounded-2xl
      child: Container(
        padding: EdgeInsets.all(16.0 * scaleFactor), // p-4
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1), // border-white/40
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicWrapper(
              intensity: 0.6,
              borderRadius: 28 * scaleFactor, // w-14 h-14 -> 56px / 2 = 28
              child: InkWell(
                onTap: () {
                  audioProvider.seekToPrevious();
                },
                borderRadius: BorderRadius.circular(28 * scaleFactor),
                child: SizedBox(
                  width: 56 * scaleFactor,
                  height: 56 * scaleFactor,
                  child: Center(
                    child: Icon(
                      Icons.skip_previous_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 24 * scaleFactor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 32 * scaleFactor), // gap-8
            NeumorphicWrapper(
              intensity: 0.6,
              borderRadius: 28 * scaleFactor, // w-14 h-14 -> 56px / 2 = 28
              child: InkWell(
                onTap: () {
                  if (audioProvider.isPlaying) {
                    audioProvider.pause();
                  } else {
                    audioProvider.resume();
                  }
                },
                borderRadius: BorderRadius.circular(28 * scaleFactor),
                child: Container(
                  width: 56 * scaleFactor,
                  height: 56 * scaleFactor,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1), // glass-inner-raised
                  ),
                  child: Center(
                    child: Icon(
                      audioProvider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: colorScheme.primary, // text-primary
                      size: 28 * scaleFactor, // w-7 h-7
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 32 * scaleFactor), // gap-8
            NeumorphicWrapper(
              intensity: 0.6,
              borderRadius: 28 * scaleFactor, // w-14 h-14 -> 56px / 2 = 28
              child: InkWell(
                onTap: () {
                  audioProvider.seekToNext();
                },
                borderRadius: BorderRadius.circular(28 * scaleFactor),
                child: SizedBox(
                  width: 56 * scaleFactor,
                  height: 56 * scaleFactor,
                  child: Center(
                    child: Icon(
                      Icons.skip_next_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 24 * scaleFactor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
