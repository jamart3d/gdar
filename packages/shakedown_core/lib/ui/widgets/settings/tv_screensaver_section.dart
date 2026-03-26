import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_stepper_row.dart';

part 'tv_screensaver_section_build.dart';
part 'tv_screensaver_section_controls.dart';

class TvScreensaverSection extends StatefulWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const TvScreensaverSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
  });

  @override
  State<TvScreensaverSection> createState() => _TvScreensaverSectionState();
}

class _TvScreensaverSectionState extends State<TvScreensaverSection> {
  static const Map<String, String> _beatDetectorDescriptions = {
    'auto':
        'Auto stays on Hybrid by default. If Enhanced Audio Capture is already active in this app session, Auto can use PCM instead.',
    'hybrid':
        'Hybrid blends low-end hits, mid transients, and broadband changes. Best default for most music.',
    'bass':
        'Bass listens for kick and low-end thump. Good when you want the pulse to follow the rhythm section.',
    'mid':
        'Mid listens more to snare, guitar, and vocal attack. Often better for live recordings and thinner mixes.',
    'broad':
        'Broad reacts to overall band energy instead of one narrow range. A safer choice when Bass or Mid feels too picky.',
    'pcm':
        'Enhanced uses Android system audio capture for cleaner onset timing and stereo waveforms. Best when you want the richest detector.',
  };

  final FocusNode _firstFocusNode = FocusNode();
  final FocusNode _lastFocusNode = FocusNode();
  int _wrapKey = 0;

  @override
  void dispose() {
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleFirstKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _wrapKey++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastFocusNode.requestFocus();
        try {
          Scrollable.ensureVisible(
            _lastFocusNode.context!,
            alignment: 1.0,
            duration: const Duration(milliseconds: 150),
          );
        } catch (_) {}
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleLastKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _wrapKey++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _firstFocusNode.requestFocus();
        try {
          Scrollable.of(_firstFocusNode.context!).position.jumpTo(0);
        } catch (_) {}
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isRingMode = settings.oilBannerDisplayMode == 'ring';
    final autoSpacing = isRingMode
        ? settings.oilAutoRingSpacing
        : settings.oilAutoTextSpacing;

    return SectionCard(
      scaleFactor: widget.scaleFactor,
      title: 'TV Screen Saver',
      icon: Icons.monitor,
      lucideIcon: LucideIcons.monitor,
      initiallyExpanded: widget.initiallyExpanded,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_wrapKey),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildSectionChildren(
              context: context,
              settings: settings,
              colorScheme: colorScheme,
              textTheme: textTheme,
              isFruit: isFruit,
              isRingMode: isRingMode,
              autoSpacing: autoSpacing,
            ),
          ),
        ),
      ],
    );
  }
}
