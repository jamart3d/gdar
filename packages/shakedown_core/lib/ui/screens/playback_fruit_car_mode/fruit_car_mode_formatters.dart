part of '../playback_screen.dart';

String fruitCarModeDateText(Show currentShow) {
  try {
    return DateFormat('MMMM d, y').format(DateTime.parse(currentShow.date));
  } catch (_) {
    return currentShow.formattedDate;
  }
}

double fruitCarModeUpcomingFontSize(int index) {
  return switch (index) {
    0 => 24,
    1 => 21,
    2 => 19,
    _ => 17,
  };
}

FontWeight fruitCarModeUpcomingFontWeight(int index) {
  return switch (index) {
    0 => FontWeight.w700,
    1 => FontWeight.w600,
    _ => FontWeight.w500,
  };
}

double fruitCarModeUpcomingOpacity(int index) {
  return switch (index) {
    0 => 0.68,
    1 => 0.48,
    2 => 0.34,
    _ => 0.24,
  };
}
