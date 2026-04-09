import 'dart:ui';

List<Color> paletteColorsForName(
  String name,
  Map<String, List<Color>> palettes,
) {
  if (palettes.isEmpty) {
    return const [Color(0xFFFFFFFF)];
  }
  return palettes[name] ?? palettes.values.first;
}

List<Color> expandPaletteColors(
  List<Color> colors, {
  int colorCount = 4,
  Color fallback = const Color(0xFFFFFFFF),
}) {
  if (colorCount <= 0) {
    return const [];
  }
  if (colors.isEmpty) {
    return List<Color>.filled(colorCount, fallback);
  }

  return List<Color>.generate(
    colorCount,
    (index) => colors[index < colors.length ? index : colors.length - 1],
  );
}
