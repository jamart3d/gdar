import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:shakedown_core/ui/screens/settings_screen.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/utils.dart';

part 'track_list_screen_build.dart';
part 'track_list_screen_fruit.dart';

class TrackListScreen extends StatefulWidget {
  final Show show;
  final Source source;

  const TrackListScreen({super.key, required this.show, required this.source});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  static const double _fruitHeaderTopGap = 14.0;
  static const double _fruitHeaderBodyHeight = 92.0;

  Uri _archiveUriForSource(Source source) {
    final String fallback = 'https://archive.org/details/${source.id}';
    if (source.tracks.isEmpty) {
      return Uri.parse(fallback);
    }

    final String? transformed = transformArchiveUrl(source.tracks.first.url);
    if (transformed == null || transformed.isEmpty) {
      return Uri.parse(fallback);
    }
    return Uri.parse(transformed);
  }

  Future<void> _openPlaybackScreen() async {
    if (context.read<DeviceService>().isTv) return;
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;

    if (isFruit) {
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FruitTabHostScreen(initialTab: 0),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
      return;
    }

    final localContext = context;
    try {
      localContext.read<AnimationController>().stop();
    } catch (_) {}

    await Navigator.of(localContext).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlaybackScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (localContext.mounted) {
      try {
        final controller = localContext.read<AnimationController>();
        unawaited(controller.repeat());
      } catch (_) {}
    }
  }

  Future<void> _playShowFromHeader() async {
    unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
    final ap = context.read<AudioProvider>();
    if (ap.currentShow != null && ap.currentShow!.name != widget.show.name) {
      await ap.stopAndClear();
    }
    unawaited(ap.playSource(widget.show, widget.source));
    await _openPlaybackScreen();
  }

  @override
  Widget build(BuildContext context) => _buildTrackListScreen(context);
}
