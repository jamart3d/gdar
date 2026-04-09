String composeScreensaverBannerText({
  required bool showInfoBanner,
  required String? title,
}) {
  if (!showInfoBanner) return '';
  return title ?? '';
}

String composeScreensaverVenue({
  required bool showInfoBanner,
  required String? venue,
}) {
  if (!showInfoBanner) return '';
  return venue ?? '';
}

String composeScreensaverDate({
  required bool showInfoBanner,
  required String? date,
}) {
  if (!showInfoBanner) return '';
  return date ?? '';
}
