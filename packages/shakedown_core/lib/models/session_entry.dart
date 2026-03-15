import 'package:hive_ce/hive.dart';

part 'session_entry.g.dart';

@HiveType(typeId: 1)
class SessionEntry {
  @HiveField(0)
  final String sourceId;
  
  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String showDate;

  SessionEntry({
    required this.sourceId,
    required this.timestamp,
    required this.showDate,
  });
}
