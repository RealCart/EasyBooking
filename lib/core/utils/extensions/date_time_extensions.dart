extension DateTimeExtensions on DateTime {
  /// Midnight of the same calendar day, in the same time zone.
  DateTime get dateOnly {
    return isUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Adds calendar days; unlike `add(Duration(days: n))` it keeps the time
  /// of day across DST changes.
  DateTime addDays(int days) {
    return isUtc
        ? DateTime.utc(
            year,
            month,
            day + days,
            hour,
            minute,
            second,
            millisecond,
            microsecond,
          )
        : DateTime(
            year,
            month,
            day + days,
            hour,
            minute,
            second,
            millisecond,
            microsecond,
          );
  }

  /// Monday of the same week, at midnight.
  DateTime get startOfWeek => dateOnly.addDays(1 - weekday);

  /// Number of nights between check-in (this) and [checkOut].
  int nightsUntil(DateTime checkOut) {
    final DateTime start = DateTime.utc(year, month, day);
    final DateTime end = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );
    return end.difference(start).inDays;
  }
}
