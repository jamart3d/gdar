import 'package:intl/intl.dart';

/// A utility class for handling consistent date formatting across the application.
class AppDateUtils {
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

  /// Default format for the show date parsing
  static String formatMonthDayYear(String rawDate) {
    if (rawDate.isEmpty) return rawDate;
    try {
      final dateTime = DateTime.parse(rawDate);
      return DateFormat.yMMMMd().format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }
}
