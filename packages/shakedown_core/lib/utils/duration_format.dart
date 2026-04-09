import 'package:shakedown_core/utils/logger.dart';

String formatDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }

  return '$minutes:$seconds';
}

Duration parseDuration(String value) {
  try {
    final parts = value
        .split(':')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    }
  } catch (error) {
    logger.w('Error parsing duration: $value');
  }

  return Duration.zero;
}
