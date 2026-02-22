import 'package:intl/intl.dart';
import 'package:shakedown/providers/settings_provider.dart';

/// A utility class for handling consistent date formatting across the application.
class AppDateUtils {
  /// Formats a raw date String (e.g. "1972-05-11" or "19720511") into a human-readable format.
  ///
  /// Optionally accepts [SettingsProvider] to respect user preferences for day of week
  /// and month abbreviation.
  ///
  /// Examples:
  /// - "19720511" -> "May 11, 1972" (Default)
  /// - "1972-05-11" with [SettingsProvider] (showDayOfWeek: true) -> "Thursday, May 11, 1972"
  static String formatDate(String rawDate, {SettingsProvider? settings}) {
    if (rawDate.isEmpty) return rawDate;

    // Normalize raw date if it's in YYYYMMDD format
    String normalized = rawDate;
    if (rawDate.length == 8 && !rawDate.contains('-')) {
      normalized =
          '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
    }

    try {
      final dateTime = DateTime.parse(normalized);

      if (settings != null) {
        String pattern = '';
        if (settings.showDayOfWeek) {
          pattern += settings.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
        }
        pattern += settings.abbreviateMonth ? 'MMM' : 'MMMM';
        pattern += ' d, y';
        return DateFormat(pattern).format(dateTime);
      }

      // Default to standard verbose format (e.g., "May 11, 1972")
      return DateFormat.yMMMMd().format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }

  /// Specialized format for year-first sorting/display: "yyyy, MMMM d"
  ///
  /// Primarily used in [Show] model for specific UI sorted lists.
  static String formatDateYearFirst(String rawDate) {
    if (rawDate.isEmpty) return rawDate;
    try {
      final dateTime = DateTime.parse(rawDate);
      return DateFormat('yyyy, MMMM d').format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }
}
