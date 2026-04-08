class UndoCheckpoint {
  const UndoCheckpoint({
    required this.sourceId,
    required this.showDate,
    required this.trackIndex,
    required this.position,
    required this.title,
    required this.createdAt,
  });

  final String sourceId;
  final String showDate;
  final int trackIndex;
  final Duration position;
  final String title;
  final DateTime createdAt;

  bool isExpiredAt(
    DateTime now, {
    Duration maxAge = const Duration(seconds: 10),
  }) {
    return now.difference(createdAt) > maxAge;
  }
}
