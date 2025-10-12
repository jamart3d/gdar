import 'track.dart';

class Source {
  final String id;
  final List<Track> tracks;

  Source({
    required this.id,
    required this.tracks,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    final List<Track> tracks = (json['tracks'] as List<dynamic>? ?? [])
        .map((trackJson) => Track.fromJson(trackJson))
        .toList();

    return Source(
      id: json['id'] as String? ?? '',
      tracks: tracks,
    );
  }
}

