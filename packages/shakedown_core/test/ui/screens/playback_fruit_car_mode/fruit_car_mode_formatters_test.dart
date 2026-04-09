import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';

Show _showWithDate(String date) {
  return Show(
    name: 'Example Show',
    artist: 'Grateful Dead',
    date: date,
    venue: 'The Venue',
    sources: [Source(id: 'source-1', tracks: [])],
  );
}

void main() {
  group('fruitCarModeDateText', () {
    test('formats a valid ISO date in month-day-year order', () {
      expect(fruitCarModeDateText(_showWithDate('1977-05-08')), 'May 8, 1977');
    });

    test('falls back to the show formatted date when parsing fails', () {
      final show = _showWithDate('not-a-date');

      expect(fruitCarModeDateText(show), show.formattedDate);
    });
  });

  group('fruitCarModeUpcomingFontSize', () {
    test('returns the expected descending sizes', () {
      expect(fruitCarModeUpcomingFontSize(0), 24);
      expect(fruitCarModeUpcomingFontSize(1), 21);
      expect(fruitCarModeUpcomingFontSize(2), 19);
      expect(fruitCarModeUpcomingFontSize(7), 17);
    });
  });

  group('fruitCarModeUpcomingFontWeight', () {
    test('returns the expected font weights', () {
      expect(fruitCarModeUpcomingFontWeight(0), FontWeight.w700);
      expect(fruitCarModeUpcomingFontWeight(1), FontWeight.w600);
      expect(fruitCarModeUpcomingFontWeight(2), FontWeight.w500);
      expect(fruitCarModeUpcomingFontWeight(7), FontWeight.w500);
    });
  });

  group('fruitCarModeUpcomingOpacity', () {
    test('returns the expected fade values', () {
      expect(fruitCarModeUpcomingOpacity(0), 0.68);
      expect(fruitCarModeUpcomingOpacity(1), 0.48);
      expect(fruitCarModeUpcomingOpacity(2), 0.34);
      expect(fruitCarModeUpcomingOpacity(7), 0.24);
    });
  });
}
