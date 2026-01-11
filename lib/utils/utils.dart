// lib/utils/utils.dart

import 'package:gdar/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

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

Duration parseDuration(String s) {
  try {
    final parts = s.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    }
  } catch (e) {
    logger.w('Error parsing duration: $s');
  }
  return Duration.zero;
}

String? transformArchiveUrl(String url) {
  // Replace 'download' with 'details'
  String newUrl = url.replaceFirst('/download/', '/details/');

  // Remove the filename (everything after the last slash)
  // But we need to be careful. The user said "chop off the late file".
  // The example shows removing the last segment.
  // "https://archive.org/details/identifier/filename.mp3" -> "https://archive.org/details/identifier/"

  final lastSlashIndex = newUrl.lastIndexOf('/');
  if (lastSlashIndex != -1) {
    newUrl = newUrl.substring(0, lastSlashIndex + 1);
  }

  return newUrl;
}

Future<void> launchArchivePage(String firstTrackUrl) async {
  // Example URL: "https://archive.org/download/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/07BirdSong.mp3"
  // Target URL: "https://archive.org/details/gd1990-10-13.141088.UltraMatrix.sbd.miller.flac1644/"

  try {
    final targetUrl = transformArchiveUrl(firstTrackUrl);
    if (targetUrl != null) {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        logger.w('Could not launch $targetUrl');
      }
    }
  } catch (e) {
    logger.e('Error parsing URL or launching archive page: $e');
  }
}

Future<void> launchArchiveDetails(String identifier) async {
  final detailsUrl = 'https://archive.org/details/$identifier';
  final detailsUri = Uri.parse(detailsUrl);

  try {
    if (await canLaunchUrl(detailsUri)) {
      await launchUrl(detailsUri);
    } else {
      logger.w('Could not launch $detailsUrl');
    }
  } catch (e) {
    logger.e('Error launching archive details page: $e');
  }
}
