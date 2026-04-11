import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/playback_list_scroll_utils.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_card.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_track_list.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_app_bar.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_view.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_scrollbar.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:shakedown_core/ui/widgets/rating_dialog.dart';

part 'tv_playback_screen_build.dart';
part 'tv_playback_screen_controls.dart';
part 'tv_playback_screen_fruit_build.dart';
part 'tv_playback_screen_helpers.dart';
part 'tv_playback_screen_layout_build.dart';

class PlaybackScreen extends StatefulWidget {
  final bool initiallyOpen;
  final bool isPane;
  final VoidCallback? onTitleTap;
  final bool enableDiceHaptics;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onScrollbarRight;
  final VoidCallback? onTrackListLeft;
  final VoidCallback? onTrackListRight;
  final bool isActive;
  final bool showFruitTabBar;
  final VoidCallback? onBackRequested;
  final VoidCallback? onRandomPlay;

  const PlaybackScreen({
    super.key,
    this.initiallyOpen = false,
    this.onTitleTap,
    this.isPane = false,
    this.enableDiceHaptics = false,
    this.scrollbarFocusNode,
    this.onScrollbarRight,
    this.onTrackListLeft,
    this.onTrackListRight,
    this.isActive = true,
    this.showFruitTabBar = true,
    this.onBackRequested,
    this.onRandomPlay,
  });

  @override
  State<PlaybackScreen> createState() => PlaybackScreenState();
}

class PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final AnimationController _pulseController;
  final PanelController _panelController = PanelController();
  final ValueNotifier<double> _panelPositionNotifier = ValueNotifier(0.0);
  StreamSubscription? _errorSubscription;
  String? _lastTrackTitle;
  int? _lastTrackNumber;
  bool? _lastStickyState;
  final Map<int, FocusNode> _trackFocusNodes = {};
  final FocusNode _trackListFocusNode = FocusNode(canRequestFocus: false);
  final FocusNode _randomPlayFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _lastTrackTitle = audioProvider.currentTrack?.title;
    _lastTrackNumber = audioProvider.currentTrack?.trackNumber;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initiallyOpen) {
        _panelController.open();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      _errorSubscription = audioProvider.playbackErrorStream.listen((error) {
        if (mounted && error.isNotEmpty) {
          showMessage(context, 'Playback Error: $error');
        }
      });
      // Removed to prevent initial bounce-scroll glitches. TrackListView now
      // handles initial positioning via its initialScrollIndex.
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _panelPositionNotifier.dispose();
    _errorSubscription?.cancel();
    for (final node in _trackFocusNodes.values) {
      node.dispose();
    }
    _trackListFocusNode.dispose();
    _randomPlayFocusNode.dispose();
    super.dispose();
  }

  void focusCurrentTrack() => _scrollToCurrentTrack(true, syncFocus: true);

  /// Called by TvDualPaneLayout when the right pane is empty (no show selected)
  /// to place D-pad focus squarely on the random play button.
  void focusRandomButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _randomPlayFocusNode.requestFocus();
    });
  }

  void _refreshTrackFocusNodes() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => _buildScreen(context);
}
