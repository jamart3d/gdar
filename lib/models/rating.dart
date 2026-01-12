import 'package:hive/hive.dart';

part 'rating.g.dart';

@HiveType(typeId: 0)
class Rating extends HiveObject {
  @HiveField(0)
  final String sourceId;

  @HiveField(1)
  final int rating; // 0=Unplayed, 1-3=Gold, -1=Blocked

  @HiveField(2)
  final DateTime timestamp;

  Rating({
    required this.sourceId,
    required this.rating,
    required this.timestamp,
  });
}
