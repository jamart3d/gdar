import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/ui/widgets/playback/dev_audio_hud.dart';

class PlaybackMessages extends StatefulWidget {
  final TextAlign textAlign;
  final bool showDivider;
  final bool compactDevHud;
  final bool showStatusLine;
  final bool showDevHudInline;
  final double fontScale;

  const PlaybackMessages({
    super.key,
    this.textAlign = TextAlign.center,
    this.showDivider = true,
    this.compactDevHud = false,
    this.showStatusLine = true,
    this.showDevHudInline = true,
    this.fontScale = 1.0,
  });

  @override
  State<PlaybackMessages> createState() => _PlaybackMessagesState();
}

class _PlaybackMessagesState extends State<PlaybackMessages>
    with WidgetsBindingObserver {
  bool _isAppVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web/desktop, a window can remain visible while unfocused ("inactive").
    // Treat that state as visible so the HUD does not collapse unexpectedly.
    _isAppVisible =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruitTheme = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.watch<DeviceService>().isTv;
    final isWebUi = kIsWeb && !isTv;
    final showDevHud =
        isWebUi && settingsProvider.showDevAudioHud && widget.showDevHudInline;
    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final double labelsFontSize = 12.0 * scaleFactor * widget.fontScale;
    final String? fontFamily = isFruitTheme ? null : 'Roboto';

    return StreamBuilder<HudSnapshot>(
      stream: audioProvider.hudSnapshotStream,
      initialData: audioProvider.currentHudSnapshot,
      builder: (context, snapshot) {
        final hud = snapshot.data;
        if (hud == null) return const SizedBox.shrink();

        if (widget.compactDevHud && !widget.showStatusLine) {
          return DevAudioHud(
            audioProvider: audioProvider,
            settingsProvider: settingsProvider,
            labelsFontSize: labelsFontSize,
            colorScheme: colorScheme,
            fontFamily: 'Roboto',
            compact: true,
            isAppVisible: _isAppVisible,
          );
        }

        String statusText = '';
        Color? statusColor;

        if (hud.signal != '--') {
          statusText = hud.message;
          statusColor = hud.signal == 'ISS' || hud.signal == 'AGT'
              ? colorScheme.error
              : colorScheme.primary;
        } else if (hud.isHandoffCountdown) {
          statusText = hud.message;
          statusColor = colorScheme.primary;
        } else if (hud.processing == 'LD') {
          statusText = 'Loading...';
        } else if (hud.processing == 'BUF') {
          statusText = 'Buffering...';
        } else {
          statusText = hud.isPlaying ? 'Playing' : 'Paused';
        }

        final hasStatusText = statusText.isNotEmpty;
        final children = <Widget>[
          if (hasStatusText)
            Text(
              statusText,
              style: TextStyle(
                color: statusColor ?? colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: labelsFontSize,
                fontFamily: fontFamily,
              ),
            ),
        ];

        final otherChildren = [
          if (settingsProvider.showPlaybackMessages) ...[
            if (!widget.showDivider && hasStatusText) const SizedBox(width: 10),
            if (widget.showDivider && hasStatusText) ...[
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: labelsFontSize,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Buffered: ${hud.buffered}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: labelsFontSize,
                fontFamily: 'Roboto',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (kIsWeb && !isTv && hud.nextBuffered != '--')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: labelsFontSize,
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next: ${hud.nextBuffered}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: labelsFontSize,
                        fontFamily: 'Roboto',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ];

        final rows = <Widget>[];
        final showStatus = settingsProvider.showPlaybackMessages;

        if (showStatus && widget.showStatusLine && hasStatusText) {
          rows.add(
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: widget.textAlign == TextAlign.center
                  ? Alignment.center
                  : widget.textAlign == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: widget.textAlign == TextAlign.center
                    ? MainAxisAlignment.center
                    : widget.textAlign == TextAlign.right
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [...children, ...otherChildren],
              ),
            ),
          );
        }

        if (showDevHud) {
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: 4));
          }
          rows.add(
            DevAudioHud(
              audioProvider: audioProvider,
              settingsProvider: settingsProvider,
              labelsFontSize: labelsFontSize,
              colorScheme: colorScheme,
              fontFamily: fontFamily,
              compact: widget.compactDevHud,
              isAppVisible: _isAppVisible,
            ),
          );
        }

        if (rows.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.textAlign == TextAlign.right
              ? CrossAxisAlignment.end
              : (widget.textAlign == TextAlign.left
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center),
          children: rows,
        );
      },
    );
  }
}
