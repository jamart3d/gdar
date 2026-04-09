import 'package:flutter/material.dart';
import 'package:gdar_design/widgets/fruit_settings_group_header.dart';

List<Widget> buildInterfaceGroupHeader({
  required String label,
  required bool isFruit,
  bool addTopSpacing = true,
}) {
  if (!isFruit) {
    if (!addTopSpacing) {
      return const [];
    }

    return const [SizedBox(height: 8), Divider(), SizedBox(height: 8)];
  }

  return [FruitSettingsGroupHeader(label: label, addTopSpacing: addTopSpacing)];
}
