/// Midnight on the first day of the week that contains [now].
/// [weekStartDay] uses DateTime constants (DateTime.monday = 1 ... DateTime.sunday = 7).
DateTime weekStartFor(DateTime now, int weekStartDay) {
  final diff = (now.weekday - weekStartDay) % 7; // Dart % is never negative here
  return DateTime(now.year, now.month, now.day - diff);
}

/// Midnight seven days after [weekStart] (exclusive end of the week).
DateTime weekEndFor(DateTime weekStart) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
