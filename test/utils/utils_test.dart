import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/utils/utils.dart';

void main() {
  group('transformArchiveUrl', () {
    test('transforms standard download URL correctly', () {
      const input =
          'https://archive.org/download/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/07BirdSong.mp3';
      const expected =
          'https://archive.org/details/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/';
      expect(transformArchiveUrl(input), expected);
    });

    test('handles URL without filename correctly', () {
      // This case might be weird if the input is already a directory, but let's see how our logic handles it.
      // Input: .../download/identifier/
      // Replace -> .../details/identifier/
      // Last slash is at the end. Substring(0, end+1) keeps it.
      const input =
          'https://archive.org/download/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/';
      const expected =
          'https://archive.org/details/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/';
      expect(transformArchiveUrl(input), expected);
    });

    test('handles URL without download segment gracefully', () {
      // If "download" is not present, replaceFirst won't change anything.
      // Then it chops off the last segment.
      const input = 'https://archive.org/other/something/file.mp3';
      const expected = 'https://archive.org/other/something/';
      expect(transformArchiveUrl(input), expected);
    });
  });
}
