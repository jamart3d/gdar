import 'dart:math';
import 'package:flutter/material.dart';

class ColorGenerator {
  /// Generates a deterministic color based on the provided seed string.
  /// Uses Material 3 dynamic color generation to ensure the color fits
  /// the system's tonal palette logic and respects brightness.
  static Color getColor(String seed,
      {Brightness brightness = Brightness.dark}) {
    final int hash = seed.hashCode;
    final Random random = Random(hash);

    // Generate a "Key Color" (Seed Color)
    // We want a vibrant seed to generate a good palette.
    final double hue = random.nextDouble() * 360;
    const double saturation = 0.8; // High saturation for the seed
    const double lightness = 0.5; // Mid lightness for the seed

    final Color keyColor =
        HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();

    // Generate a full ColorScheme from this seed
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: keyColor,
      brightness: brightness,
    );

    // Return a container color that is appropriate for backgrounds
    // surfaceContainerHigh is usually good for cards/mini-players.
    // primaryContainer is more colorful.
    // Let's use surfaceContainerHigh for a subtle but tinted look,
    // or primaryContainer for a bold look.
    // The user asked for "THE color", implying they want to see the color.
    // surfaceContainerHigh might be too subtle (greyish) depending on the seed.
    // Let's try primaryContainer, but it might be too strong for a whole screen background.
    // Actually, surfaceContainerHigh in M3 is tinted with the primary color.

    // Let's return surfaceContainerHigh as it's the standard for "MiniPlayer" background in this app.
    return scheme.surfaceContainerHigh;
  }
}
