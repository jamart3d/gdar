import 'package:intl/intl.dart';
import 'source.dart';

class Show {
  final String name;
  final String artist;
  final String date;
  String venue; // Changed from final to allow modification
  List<Source> sources; // Changed from final to allow modification
  bool hasFeaturedTrack; // Our new property

  Show({
    required this.name,
    required this.artist,
    required this.date,
    required this.venue,
    required this.sources,
    this.hasFeaturedTrack = false, // Default to false
  });

  String get formattedDate {
    try {
      // Use the 'date' field from the model for parsing
      final dateTime = DateTime.parse(date);
      return DateFormat.yMMMMd().format(dateTime);
    } catch (e) {
      // Fallback to the original date string if parsing fails
      return date;
    }
  }

  factory Show.fromJson(Map<String, dynamic> json) {
    final String? src = json['src'];
    final List<Source> sources = (json['sources'] as List<dynamic>? ?? [])
        .map((sourceJson) => Source.fromJson(sourceJson, src: src))
        .toList();

    final String showName = json['name'] ?? 'Unknown Show';
    final String date = json['date'] ?? '';

    return Show(
      name: showName,
      artist: 'Grateful Dead',
      date: date,
      venue: showName,
      sources: sources,
    );
  }

  Show copyWith({
    String? name,
    String? artist,
    String? date,
    String? venue,
    List<Source>? sources,
    bool? hasFeaturedTrack,
  }) {
    return Show(
      name: name ?? this.name,
      artist: artist ?? this.artist,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      sources: sources ?? this.sources,
      hasFeaturedTrack: hasFeaturedTrack ?? this.hasFeaturedTrack,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Show &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          date == other.date &&
          venue == other.venue;

  @override
  int get hashCode => name.hashCode ^ date.hashCode ^ venue.hashCode;
}
