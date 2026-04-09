import 'package:url_launcher/url_launcher.dart';

typedef ArchiveLaunchErrorHandler = void Function(Object error);

String? transformArchiveUrl(String url) {
  var newUrl = url.replaceFirst('/download/', '/details/');
  final lastSlashIndex = newUrl.lastIndexOf('/');
  if (lastSlashIndex != -1) {
    newUrl = newUrl.substring(0, lastSlashIndex + 1);
  }

  return newUrl;
}

Future<void> openArchivePage(
  String firstTrackUrl, {
  ArchiveLaunchErrorHandler? onError,
}) async {
  try {
    final targetUrl = transformArchiveUrl(firstTrackUrl);
    if (targetUrl == null) {
      return;
    }

    final uri = Uri.parse(targetUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $targetUrl');
    }
  } catch (error) {
    onError?.call(error);
  }
}

Future<void> openArchiveDetails(
  String identifier, {
  ArchiveLaunchErrorHandler? onError,
}) async {
  final detailsUrl = 'https://archive.org/details/$identifier';
  final detailsUri = Uri.parse(detailsUrl);

  try {
    if (!await launchUrl(detailsUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $detailsUrl');
    }
  } catch (error) {
    onError?.call(error);
  }
}
