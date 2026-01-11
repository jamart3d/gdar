import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/utils/share_link_parser.dart';

void main() {
  group('ShareLinkParser', () {
    test('parses standard share string correctly', () {
      const input =
          'West High Auditorium - Anchorage, AK - Fri, Jun 20, 1980 - 156397[crowd - tuning]https://archive.org/details/gd1980-06-20.156397.sbd.clugston.flac1644/gd80-06-20s1t01.flac';
      final result = ShareLinkParser.parse(input);

      expect(result, isNotNull);
      expect(result!.shnid, '156397');
      expect(result.trackName, 'crowd - tuning');
      expect(result.position, isNull);
    });

    test('parses share string with position correctly', () {
      const input =
          '''West High Auditorium - Anchorage, AK - Fri, Jun 20, 1980 - 156397[crowd - tuning]https://archive.org/details...
Position: 05:30''';
      final result = ShareLinkParser.parse(input);

      expect(result, isNotNull);
      expect(result!.shnid, '156397');
      expect(result.trackName, 'crowd - tuning');
      expect(result.position, const Duration(minutes: 5, seconds: 30));
    });

    test('parses share string without brackets for track name', () {
      const input =
          'Venue - Date - 1980 - 12345 Track Name https://archive.org/Foo';
      final result = ShareLinkParser.parse(input);

      expect(result, isNotNull);
      expect(result!.shnid, '12345');
      expect(result.trackName, 'Track Name');
    });

    test('returns null for string without year', () {
      const input = 'Venue - No Year - 12345';
      final result = ShareLinkParser.parse(input);
      expect(result, isNull);
    });

    test('returns null for string without SHNID', () {
      const input = 'Venue - 1980 - NoID';
      final result = ShareLinkParser.parse(input);
      expect(result, isNull);
    });

    test('handles SHNID with hyphens and dots', () {
      const input = 'Venue - 1980 - 123-456.789 [Track] https://archive.org';
      final result = ShareLinkParser.parse(input);

      expect(result, isNotNull);
      expect(result!.shnid, '123-456.789');
    });

    test('parses position with newlines and extra text', () {
      const input = '''Venue - 1980 - 12345 [Track] https://archive.org
          
          Position: 01:23
          Sent from my iPhone''';
      final result = ShareLinkParser.parse(input);

      expect(result, isNotNull);
      expect(result!.position, const Duration(minutes: 1, seconds: 23));
    });

    test('returns null for empty string', () {
      final result = ShareLinkParser.parse('');
      expect(result, isNull);
    });

    test('returns null for garbage string', () {
      final result = ShareLinkParser.parse(
          'This is just some random text without any date or id');
      expect(result, isNull);
    });
  });
}
