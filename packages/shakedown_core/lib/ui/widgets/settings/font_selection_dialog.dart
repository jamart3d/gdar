import 'package:flutter/material.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_radio_list_tile.dart';

class FontSelectionDialog extends StatelessWidget {
  const FontSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    // Map of internal value to display name and TextStyle
    final Map<String, TextStyle?> fonts = {
      'default': TextStyle(fontFamily: FontConfig.resolve('Roboto')),
      'inter': TextStyle(fontFamily: FontConfig.resolve('Inter')),
      'caveat': TextStyle(fontFamily: FontConfig.resolve('Caveat')),
      'permanent_marker': TextStyle(
        fontFamily: FontConfig.resolve('Permanent Marker'),
      ),
      'rock_salt': TextStyle(fontFamily: FontConfig.resolve('RockSalt')),
    };

    final Map<String, String> displayNames = {
      'default': 'Default (Roboto)',
      'inter': 'Inter',
      'caveat': 'Caveat',
      'permanent_marker': 'Permanent Marker',
      'rock_salt': 'Rock Salt',
    };

    return AlertDialog(
      title: const Text('Select App Font'),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: settingsProvider.appFont,
          onChanged: (String? value) {
            if (value != null) {
              AppHaptics.selectionClick(context.read<DeviceService>());
              settingsProvider.setAppFont(value);
              Navigator.of(context).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fonts.entries.map((entry) {
              return TvRadioListTile<String>(
                title: Text(
                  displayNames[entry.key]!,
                  style: entry.value?.copyWith(fontSize: 18 * scaleFactor),
                ),
                value: entry.key,
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const FontSelectionDialog();
      },
    );
  }
}
