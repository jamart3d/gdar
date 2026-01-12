import 'package:hive/hive.dart';

part 'track.g.dart';

@HiveType(typeId: 3)
class Track {
  @HiveField(0)
  final int trackNumber;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int duration; // in seconds

  @HiveField(3)
  final String url;

  @HiveField(4)
  final String setName;

  Track({
    required this.trackNumber,
    required this.title,
    required this.duration,
    required this.url,
    required this.setName,
  });

  // A 'factory constructor' that creates a Track from a JSON object.
  factory Track.fromJson(Map<String, dynamic> json,
      {String? baseUrl, String? setName}) {
    String title = json['t'] ?? 'Untitled';
    // Remove leading track numbers and separators like '01.', '01 -', '1.', etc.
    title = title.replaceFirst(RegExp(r'^\d*[\s.-]*'), '');

    String url = json['u'] ?? '';
    if (baseUrl != null && url.isNotEmpty && !url.startsWith('http')) {
      url = '$baseUrl$url';
    }

    return Track(
      trackNumber: json['n'] ?? 0,
      title: title,
      duration: json['d'] ?? 0,
      url: url,
      setName: setName ?? json['s'] ?? 'Unknown Set',
    );
  }
}
