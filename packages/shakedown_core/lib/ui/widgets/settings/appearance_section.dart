import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/ui/widgets/settings/font_selection_dialog.dart';
import 'package:shakedown_core/ui/widgets/settings/appearance_fruit_controls.dart';
import 'package:shakedown_core/ui/widgets/settings/appearance_fx_controls.dart';
import 'package:shakedown_core/ui/widgets/settings/appearance_theme_controls.dart';
import 'package:lucide_icons/lucide_icons.dart';
part 'appearance_section_build.dart';

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

  @override
  Widget build(BuildContext context) => _buildAppearanceSection(context);
}
