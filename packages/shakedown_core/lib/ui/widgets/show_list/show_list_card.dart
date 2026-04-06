import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/show_list/card_style_utils.dart';
import 'package:shakedown_core/ui/widgets/show_list/embedded_mini_player.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/ui/widgets/rating_dialog.dart';

part 'show_list_card_build.dart';
part 'show_list_card_controls.dart';
part 'show_list_card_fruit_car_mode.dart';
part 'show_list_card_fruit_mobile.dart';

/// A card displaying summary information for a [Show].
class ShowListCard extends StatefulWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final Source? playingSource;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool alwaysShowRatingInteraction;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;

  const ShowListCard({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    this.playingSource,
    required this.isLoading,
    required this.onTap,
    required this.onLongPress,
    this.alwaysShowRatingInteraction = false,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
  });

  @override
  State<ShowListCard> createState() => _ShowListCardState();
}

class _ShowListCardState extends State<ShowListCard> {
  static const Duration _animationDuration = Duration(milliseconds: 80);
  bool _isHovered = false;

  void _onHover(bool isHovering) {
    if (_isHovered != isHovering) {
      setState(() => _isHovered = isHovering);
    }
    widget.onFocusChange?.call(isHovering);
  }

  @override
  Widget build(BuildContext context) => _buildShowListCard(context);
}
