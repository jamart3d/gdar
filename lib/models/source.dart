import 'track.dart';

class Source {
  final String id;
  final String? src;
  final List<Track> tracks;

  Source({
    required this.id,
    this.src,
    required this.tracks,
  });

  factory Source.fromJson(Map<String, dynamic> json, {String? src}) {
    final List<Track> tracks = (json['tracks'] as List<dynamic>? ?? [])
        .map((trackJson) => Track.fromJson(trackJson))
        .toList();

    return Source(
      id: json['id'] as String? ?? '',
      src: src,
      tracks: tracks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Source && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
