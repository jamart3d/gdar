import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/ui/widgets/settings/color_picker_dialog.dart';
import 'package:shakedown_core/ui/widgets/settings/font_selection_dialog.dart';
import 'package:shakedown_core/ui/widgets/settings/rainbow_color_picker.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:lucide_icons/lucide_icons.dart';

part 'appearance_section_build.dart';
part 'appearance_section_controls.dart';

class AppearanceSection extends StatefulWidget {
  final double scaleFactor;
  final bool initiallyExpanded;
  final bool showFontSelection;

  const AppearanceSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
    this.showFontSelection = false,
  });

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  @override
  void initState() {
    super.initState();
    if (widget.showFontSelection) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          FontSelectionDialog.show(context);
        }
      });
    }
  }

  String _getFontDisplayName(String fontKey) {
    switch (fontKey) {
      case 'caveat':
        return 'Caveat';
      case 'permanent_marker':
        return 'Permanent Marker';
      case 'rock_salt':
        return 'Rock Salt';
      default:
        return 'Default (Roboto)';
    }
  }

  @override
  Widget build(BuildContext context) => _buildAppearanceSection(context);
}
