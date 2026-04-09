import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/steal_screensaver/background/palette_utils.dart';

void main() {
  group('paletteColorsForName', () {
    const palettes = {
      'alpha': [Color(0xFF111111), Color(0xFF222222)],
      'beta': [Color(0xFF333333)],
    };

    test('returns the named palette when present', () {
      expect(paletteColorsForName('beta', palettes), const [Color(0xFF333333)]);
    });

    test('falls back to the first palette when missing', () {
      expect(paletteColorsForName('missing', palettes), const [
        Color(0xFF111111),
        Color(0xFF222222),
      ]);
    });

    test('falls back to white when palette map is empty', () {
      expect(paletteColorsForName('missing', const {}), const [
        Color(0xFFFFFFFF),
      ]);
    });
  });

  group('expandPaletteColors', () {
    test('pads with the last entry until the requested color count', () {
      expect(
        expandPaletteColors(const [
          Color(0xFF010101),
          Color(0xFF020202),
        ], colorCount: 4),
        const [
          Color(0xFF010101),
          Color(0xFF020202),
          Color(0xFF020202),
          Color(0xFF020202),
        ],
      );
    });

    test('truncates palettes longer than the requested color count', () {
      expect(
        expandPaletteColors(const [
          Color(0xFF000001),
          Color(0xFF000002),
          Color(0xFF000003),
        ], colorCount: 2),
        const [Color(0xFF000001), Color(0xFF000002)],
      );
    });

    test(
      'uses the provided fallback when asked to expand an empty palette',
      () {
        expect(
          expandPaletteColors(
            const [],
            colorCount: 3,
            fallback: const Color(0xFFABCDEF),
          ),
          const [Color(0xFFABCDEF), Color(0xFFABCDEF), Color(0xFFABCDEF)],
        );
      },
    );
  });
}
