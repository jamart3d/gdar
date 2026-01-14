import 'package:shakedown/utils/utils.dart'; // For parseDuration

/// Data class to hold the parsed information from a share link.
class ShareLinkData {
  final String shnid;
  final String? trackName;
  final Duration? position;

  ShareLinkData({
    required this.shnid,
    this.trackName,
    this.position,
  });

  @override
  String toString() {
    return 'ShareLinkData(shnid: $shnid, trackName: $trackName, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShareLinkData &&
        other.shnid == shnid &&
        other.trackName == trackName &&
        other.position == position;
  }

  @override
  int get hashCode => shnid.hashCode ^ trackName.hashCode ^ position.hashCode;
}

class ShareLinkParser {
  /// Parses a share string and returns [ShareLinkData] if reliable information is found.
  ///
  /// Format expected:
  /// Line 1: Venue - Date - SHNID
  /// Line 2: Track Title
  /// Line 3: Archive URL
  /// Line 4: Position: MM:SS (Optional)
  static ShareLinkData? parse(String shareString) {
    final cleanShare = shareString.trim();
    if (cleanShare.isEmpty) return null;

    try {
      // Parse structure: [venue] - [location] - [date] - [SHNID][track name][URL]
      // Example: "West High Auditorium - Anchorage, AK - Fri, Jun 20, 1980 - 156397[crowd - tuning]https://..."

      // Find the year (4 digits between 1960-2030) as an anchor
      final yearMatch = RegExp(r'(19[6-9]\d|20[0-2]\d)').firstMatch(cleanShare);
      if (yearMatch == null) {
        return null;
      }

      // Extract everything after the year
      final afterYear = cleanShare.substring(yearMatch.end);

      // SHNID comes after " - " following the year
      final shnidStart = afterYear.indexOf(' - ');
      if (shnidStart == -1) {
        return null;
      }

      // Extract SHNID: starts after " - ", capture only digits/hyphens/dots until we hit a letter or bracket
      final shnidText = afterYear.substring(shnidStart + 3).trim();
      String shnid = '';
      int shnidEnd = 0;

      for (int i = 0; i < shnidText.length; i++) {
        final char = shnidText[i];
        // SHNID can contain digits, dots, hyphens
        if (RegExp(r'[0-9.\-]').hasMatch(char)) {
          shnid += char;
          shnidEnd = i + 1;
        } else {
          // Stop at first non-SHNID character (letter, bracket, etc)
          break;
        }
      }
      shnid = shnid.trim();

      if (shnid.isEmpty) {
        return null;
      }

      // Extract track name: everything after SHNID until "[", "https", or end
      String? trackName;
      if (shnidEnd < shnidText.length) {
        String afterShnid = shnidText.substring(shnidEnd).trim();

        // Try to extract from brackets first: [track name]
        final trackMatch = RegExp(r'\[([^\]]+)\]').firstMatch(afterShnid);
        if (trackMatch != null) {
          trackName = trackMatch.group(1);
        } else {
          // Otherwise, take everything until "https" or end of string
          final urlLower = afterShnid.toLowerCase();
          final urlIndex = urlLower.indexOf('https');
          if (urlIndex != -1) {
            trackName = afterShnid.substring(0, urlIndex).trim();
          } else {
            trackName = afterShnid.trim();
          }
          // Remove any trailing brackets or special chars
          trackName = trackName.replaceAll(RegExp(r'[\[\]]'), '').trim();
        }

        if (trackName!.isEmpty) {
          trackName = null;
        }
      }

      // Parse Position (Optional)
      Duration? pos;
      final lowerShare = cleanShare.toLowerCase();
      final posIndex = lowerShare.indexOf('position:');
      if (posIndex != -1) {
        final posPart =
            lowerShare.substring(posIndex + 'position:'.length).trim();
        final timeStr = posPart.split(' ').first.split('\n').first;
        pos = parseDuration(timeStr);
      }

      return ShareLinkData(shnid: shnid, trackName: trackName, position: pos);
    } catch (e) {
      // Any parsing error results in failure
      return null;
    }
  }
}
