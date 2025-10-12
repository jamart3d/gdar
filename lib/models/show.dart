import 'package:intl/intl.dart';
import 'source.dart';

class Show {
  final String name;
  final String artist;
  final String date;
  final String year;
  final String venue;
  final List<Source> sources;

  Show({
    required this.name,
    required this.artist,
    required this.date,
    required this.year,
    required this.venue,
    required this.sources,
  });

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat.yMMMMd().format(dateTime);
    } catch (e) {
      return date;
    }
  }

  factory Show.fromJson(Map<String, dynamic> json) {
    final List<Source> sources = (json['sources'] as List<dynamic>? ?? [])
        .map((sourceJson) => Source.fromJson(sourceJson))
        .toList();

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
      sources: sources,
    );
  }
}

