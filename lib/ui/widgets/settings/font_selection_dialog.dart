import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/ui/widgets/tv/tv_radio_list_tile.dart';

class FontSelectionDialog extends StatelessWidget {
  const FontSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // Map of internal value to display name and TextStyle
    final Map<String, TextStyle?> fonts = {
      'default': const TextStyle(fontFamily: 'Roboto'), // Enforce Roboto
      'caveat': const TextStyle(fontFamily: 'Caveat'),
      'permanent_marker': const TextStyle(fontFamily: 'Permanent Marker'),
      'rock_salt': const TextStyle(fontFamily: 'RockSalt'),
    };

    final Map<String, String> displayNames = {
      'default': 'Default (Roboto)',
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
              HapticFeedback.selectionClick();
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
                  style: entry.value?.copyWith(
                    fontSize: 18 * scaleFactor,
                  ),
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
