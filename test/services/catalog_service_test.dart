import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/services/catalog_service.dart';

void main() {
  group('CatalogService Parsing Logic', () {
    test('parseShows merges sources for the same date/show', () {
      // Input: Two entries for the same date, different sources
      final jsonInput = jsonEncode([
        {
          "date": "1977-05-08",
          "name": "Cornell University",
          "l": "Ithaca, NY",
          "sources": [
            {
              "id": "1",
              "src": "sbd",
              "tracks": [
                {"t": "Minglewood", "d": 300, "u": "url1"}
              ]
            }
          ]
        },
        {
          "date": "1977-05-08",
          // Different venue name to test unification
          "name": "Barton Hall, Cornell",
          "sources": [
            {
              "id": "2",
              "src": "aud",
              "tracks": [
                {"t": "Minglewood", "d": 305, "u": "url2"}
              ]
            }
          ]
        }
      ]);

      final results = CatalogService.parseShows(jsonInput);

      // Verify Unification
      expect(results.length, 1, reason: 'Should merge into a single show');

      final show = results.first;
      expect(show.date, '1977-05-08');

      // Verify Sources Merged
      expect(show.sources.length, 2);
      expect(show.sources.map((s) => s.id).toList(), containsAll(['1', '2']));

      // Verify Venue Unification (First valid one encountered usually wins or is consistent)
      // The implementation details say: if dateToVenue contains it, use that.
      // So the first one processed sets the venue for that date.
      expect(show.venue, 'Cornell University');
    });

    test('parseShows correctly identifies featured tracks', () {
      final jsonInput = jsonEncode([
        {
          "date": "1980-01-01",
          "name": "Venue",
          "sources": [
            {
              "id": "1",
              "src": "sbd",
              "tracks": [
                {"t": "GDTRFB", "d": 300, "u": "url1"} // Starts with GD
              ]
            }
          ]
        },
        {
          "date": "1980-01-02",
          "name": "Venue 2",
          "sources": [
            {
              "id": "2",
              "src": "sbd",
              "tracks": [
                {"t": "Not Featured", "d": 300, "u": "url1"}
              ]
            }
          ]
        }
      ]);

      final results = CatalogService.parseShows(jsonInput);

      expect(results.length, 2);

      // First show has GD track
      final show1 = results.firstWhere((s) => s.date == '1980-01-01');
      expect(show1.hasFeaturedTrack, isTrue, reason: 'Should detect GD track');

      // Second show does not
      final show2 = results.firstWhere((s) => s.date == '1980-01-02');
      expect(show2.hasFeaturedTrack, isFalse);
    });

    test('parseShows sorts shows by date', () {
      final jsonInput = jsonEncode([
        {"date": "1990-01-01", "name": "Show B", "sources": []},
        {"date": "1980-01-01", "name": "Show A", "sources": []},
        {"date": "1970-01-01", "name": "Show C", "sources": []},
      ]);

      final results = CatalogService.parseShows(jsonInput);

      expect(results.length, 3);
      expect(results[0].date, '1970-01-01');
      expect(results[1].date, '1980-01-01');
      expect(results[2].date, '1990-01-01');
    });

    test('parseShows handles duplicate sources gracefully', () {
      final jsonInput = jsonEncode([
        {
          "date": "1977-05-08",
          "name": "Cornell",
          "sources": [
            {"id": "1", "src": "sbd", "tracks": []}
          ]
        },
        {
          "date": "1977-05-08",
          "name": "Cornell",
          "sources": [
            {"id": "1", "src": "sbd", "tracks": []} // Duplicate ID
          ]
        }
      ]);

      final results = CatalogService.parseShows(jsonInput);
      final show = results.first;

      // Should handle duplicates by checking ID existence
      expect(show.sources.length, 1,
          reason: 'Should not add duplicate source IDs');
    });
  });
}
