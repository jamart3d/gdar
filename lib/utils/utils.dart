// lib/utils/utils.dart

String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
