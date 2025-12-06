class Track {
  final int trackNumber;
  final String title;
  final int duration; // in seconds
  final String url;
  final String setName;

  Track({
    required this.trackNumber,
    required this.title,
    required this.duration,
    required this.url,
    required this.setName,
  });

  // A 'factory constructor' that creates a Track from a JSON object.
  factory Track.fromJson(Map<String, dynamic> json) {
    String title = json['t'] ?? 'Untitled';
    // Remove leading track numbers and separators like '01.', '01 -', '1.', etc.
    title = title.replaceFirst(RegExp(r'^\d*[\s.-]*'), '');

    return Track(
      trackNumber: json['n'] ?? 0,
      title: title,
      duration: json['d'] ?? 0,
      url: json['u'] ?? '',
      setName: json['s'] ?? 'Unknown Set',
    );
  }
}
