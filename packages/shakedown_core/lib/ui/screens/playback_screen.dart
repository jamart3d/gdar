import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/dng_snapshot.dart';
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
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_pending_overlay.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_track_list.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_app_bar.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_view.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_activity_indicator.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_scrollbar.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/color_generator.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/ui/widgets/backgrounds/floating_spheres_background.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:shakedown_core/ui/widgets/rating_dialog.dart';

part 'playback_screen_build.dart';
part 'playback_screen_controls.dart';
part 'playback_screen_fruit_build.dart';
part 'playback_fruit_car_mode/fruit_car_mode_scaffold.dart';
part 'playback_fruit_car_mode/fruit_car_mode_hud.dart';
part 'playback_fruit_car_mode/fruit_car_mode_progress.dart';
part 'playback_fruit_car_mode/fruit_car_mode_controls.dart';
part 'playback_fruit_car_mode/fruit_car_mode_formatters.dart';
part 'playback_screen_fruit_car_mode.dart';
part 'playback_screen_fruit_widgets.dart';
part 'playback_screen_helpers.dart';
part 'playback_screen_layout_build.dart';

@visibleForTesting
double computeFruitFloatingNowPlayingBottomOffset({
  required bool stickyNowPlaying,
  required bool hasCurrentTrack,
  required bool showCompactHud,
  required double scaleFactor,
  required double bottomSafeArea,
  required double measuredCardHeight,
}) {
  if (stickyNowPlaying || !hasCurrentTrack) {
    return 0.0;
  }

  final double estimatedCardHeight =
      (78.0 * scaleFactor) + (showCompactHud ? 126.0 * scaleFactor : 0.0);
  final double reservedCardHeight = math.max(
    measuredCardHeight,
    estimatedCardHeight,
  );
  final double baseMargin = (5.0 * scaleFactor) + bottomSafeArea;
  return reservedCardHeight + baseMargin + (12.0 * scaleFactor);
}

@visibleForTesting
bool computeFruitCarModePendingCue({
  required bool isLoading,
  required bool isBuffering,
  required int bufferedPositionMs,
  required int positionMs,
  required int durationMs,
}) {
  final int remainingMs = durationMs - positionMs;
  final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
  final bool hasVisibleBufferHeadroom = bufferedPositionMs > (positionMs + 350);
  return isLoading ||
      isBuffering ||
      (hasPlayableTail && !hasVisibleBufferHeadroom);
}

@visibleForTesting
FruitCarModeProgressMetrics computeFruitCarModeProgressMetrics({
  required Duration position,
  required Duration buffered,
  required Duration total,
}) {
  final totalMs = total.inMilliseconds;
  final maxProgressMs = totalMs > 0 ? totalMs : 0;
  final positionMs = position.inMilliseconds.clamp(0, maxProgressMs);
  final bufferedMs = buffered.inMilliseconds.clamp(0, maxProgressMs);

  return FruitCarModeProgressMetrics(
    totalMs: totalMs,
    positionMs: positionMs,
    bufferedMs: bufferedMs,
    progress: totalMs <= 0 ? 0.0 : positionMs / totalMs,
    bufferedProgress: totalMs <= 0 ? 0.0 : bufferedMs / totalMs,
  );
}

@visibleForTesting
class FruitCarModeProgressMetrics {
  const FruitCarModeProgressMetrics({
    required this.totalMs,
    required this.positionMs,
    required this.bufferedMs,
    required this.progress,
    required this.bufferedProgress,
  });

  final int totalMs;
  final int positionMs;
  final int bufferedMs;
  final double progress;
  final double bufferedProgress;
}

@visibleForTesting
double computeFruitCarModeHeadroomFill({
  required Duration headroom,
  double fullScaleSeconds = 30.0,
}) {
  final double headroomSeconds = headroom.inMilliseconds / 1000.0;
  if (headroomSeconds <= 0) {
    return 0.0;
  }
  if (fullScaleSeconds <= 0) {
    return 1.0;
  }
  return (headroomSeconds / fullScaleSeconds).clamp(0.0, 1.0);
}

@visibleForTesting
double computeFruitCarModeNextTrackFill({
  required Duration nextBuffered,
  required Duration? nextTotal,
}) {
  final total = nextTotal;
  if (total == null || total <= Duration.zero) {
    return nextBuffered > Duration.zero ? 1.0 : 0.0;
  }
  return (nextBuffered.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
}

@visibleForTesting
Duration? parseFruitCarModeDurationText(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '--') {
    return null;
  }

  final unitMatch = RegExp(r'^([+-]?\d+(?:\.\d+)?)(ms|s)$').firstMatch(trimmed);
  if (unitMatch != null) {
    final double? amount = double.tryParse(unitMatch.group(1)!);
    final String unit = unitMatch.group(2)!;
    if (amount == null) {
      return null;
    }
    final double magnitude = amount.abs();
    final int millis = unit == 's'
        ? (magnitude * 1000).round()
        : magnitude.round();
    return Duration(milliseconds: millis);
  }

  final parts = trimmed.split(':');
  if (parts.length < 2 || parts.length > 3) {
    return null;
  }

  final values = parts.map(int.tryParse).toList(growable: false);
  if (values.any((value) => value == null)) {
    return null;
  }

  if (values.length == 2) {
    return Duration(minutes: values[0]!, seconds: values[1]!);
  }

  return Duration(hours: values[0]!, minutes: values[1]!, seconds: values[2]!);
}

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
  bool? _lastStickyState;
  final GlobalKey _fruitFloatingNowPlayingKey = GlobalKey();
  double _fruitFloatingNowPlayingHeight = 0.0;
  bool _fruitFloatingNowPlayingMeasurementQueued = false;
  bool _fruitCarModeHudShowsMeta = false;
  bool _fruitCarModeEntryResyncTriggered = false;
  HudSnapshot? _fruitCarModeFrozenHud;
  double? _fruitCarModeLastMeasuredGapMs;
  Duration _fruitCarModeRenderedPosition = Duration.zero;
  Duration _fruitCarModeRenderedTotal = Duration.zero;
  double _fruitCarModeRenderedProgress = 0.0;
  DateTime? _fruitCarModeRenderedAt;
  PlayerState? _fruitCarModeRenderedPlayerState;
  Timer? _fruitCarModeSyncProbeTimer;
  DateTime? _fruitCarModeSyncProbeUntil;
  String? _fruitCarModeSyncProbeTrigger;
  final Map<int, FocusNode> _trackFocusNodes = {};
  final FocusNode _trackListFocusNode = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _lastTrackTitle = audioProvider.currentTrack?.title;
    _fruitCarModeFrozenHud = audioProvider.currentHudSnapshot;
    final initialGap = _fruitCarModeFrozenHud?.lastGapMs;
    if (initialGap != null && initialGap.isFinite && initialGap > 0) {
      _fruitCarModeLastMeasuredGapMs = initialGap;
    }
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
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _panelPositionNotifier.dispose();
    _errorSubscription?.cancel();
    _fruitCarModeSyncProbeTimer?.cancel();
    for (final node in _trackFocusNodes.values) {
      node.dispose();
    }
    _trackListFocusNode.dispose();
    super.dispose();
  }

  void focusCurrentTrack() => _focusCurrentTrackImpl();

  void _refreshTrackFocusNodes() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateFruitFloatingNowPlayingHeight(double measuredHeight) {
    if (!mounted) return;
    setState(() {
      _fruitFloatingNowPlayingHeight = measuredHeight;
    });
  }

  void toggleFruitCarModeHud() {
    if (!mounted) return;
    setState(() {
      _fruitCarModeHudShowsMeta = !_fruitCarModeHudShowsMeta;
    });
  }

  @override
  Widget build(BuildContext context) => _buildScreen(context);
}
