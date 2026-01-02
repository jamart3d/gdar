import 'track.dart';

class Source {
  final String id;
  final String? src;
  final List<Track> tracks;

  final String? location;

  Source({
    required this.id,
    this.src,
    required this.tracks,
    this.location,
  });

  factory Source.fromJson(Map<String, dynamic> json,
      {String? src, String? showLocation}) {
    String? baseDir = json['_d'];
    String? baseUrl;
    if (baseDir != null) {
      baseUrl = 'https://archive.org/download/$baseDir/';
    }

    final List<Track> tracks = [];

    // Handle new 'sets' structure
    if (json.containsKey('sets')) {
      final List<dynamic> setsJson = json['sets'] as List<dynamic>;
      for (final setJson in setsJson) {
        final String setName = setJson['n'] ?? 'Unknown Set';
        final List<dynamic> tracksJson = setJson['t'] as List<dynamic>? ?? [];
        for (final trackJson in tracksJson) {
          tracks.add(
              Track.fromJson(trackJson, baseUrl: baseUrl, setName: setName));
        }
      }
    } else {
      // Fallback for old 'tracks' structure
      final List<dynamic> tracksJson = json['tracks'] as List<dynamic>? ?? [];
      for (final trackJson in tracksJson) {
        tracks.add(Track.fromJson(trackJson, baseUrl: baseUrl));
      }
    }

    return Source(
      id: json['id'] as String? ?? '',
      src: json['src'] ?? src,
      tracks: tracks,
      location: (json['l'] as String?) ?? showLocation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Source && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
