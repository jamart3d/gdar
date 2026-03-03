import 'package:flutter/material.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ColorPickerDialog();
      },
    );
  }
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    pickerColor = settingsProvider.seedColor ?? Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();

    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: (color) => setState(() => pickerColor = color),
          paletteType: PaletteType.hsl,
          pickerAreaHeightPercent: 0.0,
          enableAlpha: false,
          labelTypes: const [],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Default'),
          onPressed: () {
            AppHaptics.lightImpact(context.read<DeviceService>());
            settingsProvider.setSeedColor(null);
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            AppHaptics.lightImpact(context.read<DeviceService>());
            settingsProvider.setSeedColor(pickerColor);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
