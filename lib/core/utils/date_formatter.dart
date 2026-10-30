/// Russian date and time formats used by the screens.
///
/// The app has no localization package yet, so the names are defined here.
/// Pass `now` explicitly to relative formats so callers and tests control
/// the clock. Values are formatted as given: convert server UTC times with
/// `toLocal()` (or to the property's time zone) before formatting.
abstract final class DateFormatter {
  static const List<String> _monthsGenitive = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const List<String> _monthsNominative = <String>[
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static const List<String> _monthsShort = <String>[
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  static const List<String> _weekdays = <String>[
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  static const List<String> _weekdaysShort = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  /// `14:00`
  static String time(DateTime date) {
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  /// `22 октября`, or `22 окт` when [short].
  static String dayMonth(DateTime date, {bool short = false}) {
    return '${date.day} ${_month(date, short: short)}';
  }

  /// `22 октября 2026`
  static String fullDate(DateTime date) {
    return '${dayMonth(date)} ${date.year}';
  }

  /// `Четверг, 22 октября`
  static String weekdayDayMonth(DateTime date) {
    return '${_capitalize(weekday(date))}, ${dayMonth(date)}';
  }

  /// `22 октября, четверг`
  static String dayMonthWeekday(DateTime date) {
    return '${dayMonth(date)}, ${weekday(date)}';
  }

  /// `Октябрь 2026`
  static String monthYear(DateTime date) {
    return '${_monthsNominative[date.month - 1]} ${date.year}';
  }

  /// `четверг`
  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

  /// `Чт`
  static String weekdayShort(DateTime date) {
    return _weekdaysShort[date.weekday - 1];
  }

  /// `22–25 октября` within one month, `30 сентября – 2 октября` across
  /// months; years are omitted. Uses short month names when [short].
  static String dayRange(DateTime start, DateTime end, {bool short = false}) {
    if (start.year == end.year && start.month == end.month) {
      if (start.day == end.day) {
        return dayMonth(start, short: short);
      }
      return '${start.day}–${end.day} ${_month(end, short: short)}';
    }
    return '${dayMonth(start, short: short)} – ${dayMonth(end, short: short)}';
  }

  /// `сегодня, 09:38`, `вчера, 18:10`, `завтра, 12:00`, otherwise
  /// `22 октября, 09:38`.
  static String relativeDayTime(DateTime date, {required DateTime now}) {
    final int dayDifference = _dateOnly(date).difference(_dateOnly(now)).inDays;
    final String day = switch (dayDifference) {
      0 => 'сегодня',
      -1 => 'вчера',
      1 => 'завтра',
      _ => dayMonth(date),
    };
    return '$day, ${time(date)}';
  }

  /// `00:28` for a countdown such as the SMS resend timer.
  static String countdown(Duration duration) {
    final Duration value = duration.isNegative ? Duration.zero : duration;
    final int minutes = value.inMinutes;
    final int seconds = value.inSeconds.remainder(60);
    return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  static String _month(DateTime date, {required bool short}) {
    return short
        ? _monthsShort[date.month - 1]
        : _monthsGenitive[date.month - 1];
  }

  // Calendar days, so a DST change does not shift the day difference.
  static DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
