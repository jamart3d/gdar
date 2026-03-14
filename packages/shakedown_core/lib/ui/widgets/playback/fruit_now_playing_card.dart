import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/widgets/web_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/liquid_glass_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/ui/widgets/fruit_icon_button.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
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

    return NeumorphicWrapper(
      enabled: settingsProvider.useNeumorphism && !isSimple,
      intensity: 0.8,
      borderRadius: 16.0 * scaleFactor,
      child: LiquidGlassWrapper(
        enabled: settingsProvider.fruitEnableLiquidGlass && !isSimple,
        borderRadius: BorderRadius.circular(16.0 * scaleFactor),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0 * scaleFactor),
            color: isSimple
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
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
                        const Flexible(
                          child: PlaybackMessages(
                            textAlign: TextAlign.left,
                            showDivider: false,
                            showDevHudInline: false,
                          ),
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        _buildDurationInfo(
                          audioProvider,
                          colorScheme,
                          isSimple: isSimple,
                        ),
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
                          initialData:
                              audioProvider.audioPlayer.bufferedPosition,
                          builder: (context, bufferedSnapshot) {
                            final buffered =
                                bufferedSnapshot.data ?? Duration.zero;
                            return _buildCompactProgressBar(
                              audioProvider,
                              colorScheme,
                              isLoading: isLoading,
                              isBuffering: isBuffering,
                              bufferedPositionMs: buffered.inMilliseconds,
                              isSimple: isSimple,
                            );
                          },
                        );
                      },
                    ),
                    if (kIsWeb && settingsProvider.showDevAudioHud) ...[
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
              SizedBox(width: 12 * scaleFactor),
              // Skip Next Button (Compact)
              if (showNext)
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
    void activate() {
      AppHaptics.lightImpact(context.read<DeviceService>());
      if (audioProvider.isPlaying) {
        audioProvider.pause();
      } else {
        audioProvider.resume();
      }
    }

    return Semantics(
      button: true,
      toggled: audioProvider.isPlaying,
      label: audioProvider.isPlaying ? 'Pause playback' : 'Resume playback',
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
                child: Icon(
                  audioProvider.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  size: 18 * scaleFactor,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
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
    final double progress =
        (duration > 0) ? (position / duration).clamp(0.0, 1.0) : 0.0;
    final double bufferedProgress =
        (duration > 0) ? (bufferedPositionMs / duration).clamp(0.0, 1.0) : 0.0;
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
