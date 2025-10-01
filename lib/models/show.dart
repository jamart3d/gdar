// lib/models/show.dart

import 'package:intl/intl.dart';
import 'track.dart';

class Show {
  final String name;
  final String artist;
  final String date; // The original date string, e.g., "1969-08-30"
  final String year;
  final String venue;
  final List<Track> tracks;

  Show({
    required this.name,
    required this.artist,
    required this.date,
    required this.year,
    required this.venue,
    required this.tracks,
  });

  /// A getter to provide a human-readable date format.
  /// Example: "August 30, 1969"
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      // Using the intl package for robust and clean date formatting.
      return DateFormat.yMMMMd().format(dateTime);
    } catch (e) {
      // If parsing fails for any reason, fall back to the original string.
      return date;
    }
  }

  factory Show.fromJson(Map<String, dynamic> json) {
    List<Track> allTracks = [];
    if (json['sources'] != null) {
      for (var source in json['sources']) {
        if (source['tracks'] != null) {
          for (var trackJson in source['tracks']) {
            allTracks.add(Track.fromJson(trackJson));
          }
        }
      }
    }

    String parseVenue(String name) {
      if (name.contains(' at ') && name.contains(' on ')) {
        try {
          return name.split(' at ')[1].split(' on ')[0];
        } catch (e) {
          return 'Unknown Venue';
        }
      }
      return 'Unknown Venue';
    }

    final String showName = json['name'] ?? 'Unknown Show';

    return Show(
      name: showName,
      artist: json['artist'] ?? 'Unknown Artist',
      date: json['date'] ?? '',
      year: json['year'] ?? '',
      venue: parseVenue(showName),
      tracks: allTracks,
    );
  }
}