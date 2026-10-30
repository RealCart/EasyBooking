import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/date_formatter.dart';

void main() {
  // Thursday.
  final DateTime thursday = DateTime(2026, 10, 22, 9, 5);

  group('DateFormatter', () {
    test('time pads hours and minutes', () {
      expect(DateFormatter.time(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(DateFormatter.time(DateTime(2026, 1, 1, 14)), '14:00');
      expect(DateFormatter.time(DateTime(2026, 1, 1, 23, 59)), '23:59');
      expect(DateFormatter.time(DateTime(2026, 1, 1)), '00:00');
    });

    test('dayMonth uses genitive or short month names', () {
      expect(DateFormatter.dayMonth(thursday), '22 октября');
      expect(DateFormatter.dayMonth(thursday, short: true), '22 окт');
      expect(DateFormatter.dayMonth(DateTime(2026, 5, 1)), '1 мая');
      expect(
        DateFormatter.dayMonth(DateTime(2026, 5, 1), short: true),
        '1 мая',
      );
    });

    test('every month has a genitive, short and nominative name', () {
      const List<String> genitive = <String>[
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
      const List<String> short = <String>[
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
      const List<String> nominative = <String>[
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
      for (int month = 1; month <= 12; month++) {
        final DateTime date = DateTime(2026, month, 3);
        expect(DateFormatter.dayMonth(date), '3 ${genitive[month - 1]}');
        expect(
          DateFormatter.dayMonth(date, short: true),
          '3 ${short[month - 1]}',
        );
        expect(DateFormatter.monthYear(date), '${nominative[month - 1]} 2026');
      }
    });

    test('fullDate appends the year', () {
      expect(DateFormatter.fullDate(thursday), '22 октября 2026');
    });

    test('weekdayDayMonth capitalizes the weekday', () {
      expect(DateFormatter.weekdayDayMonth(thursday), 'Четверг, 22 октября');
    });

    test('dayMonthWeekday keeps the weekday lowercase', () {
      expect(DateFormatter.dayMonthWeekday(thursday), '22 октября, четверг');
    });

    test('monthYear uses the nominative month', () {
      expect(DateFormatter.monthYear(thursday), 'Октябрь 2026');
    });

    test('weekday and weekdayShort cover Monday to Sunday', () {
      // 19 October 2026 is a Monday.
      final List<DateTime> week = List<DateTime>.generate(
        7,
        (int index) => DateTime(2026, 10, 19 + index),
      );

      expect(week.map(DateFormatter.weekday), <String>[
        'понедельник',
        'вторник',
        'среда',
        'четверг',
        'пятница',
        'суббота',
        'воскресенье',
      ]);
      expect(week.map(DateFormatter.weekdayShort), <String>[
        'Пн',
        'Вт',
        'Ср',
        'Чт',
        'Пт',
        'Сб',
        'Вс',
      ]);
    });

    group('dayRange', () {
      test('within one month shows the month once', () {
        expect(
          DateFormatter.dayRange(
            DateTime(2026, 10, 22),
            DateTime(2026, 10, 25),
          ),
          '22–25 октября',
        );
        expect(
          DateFormatter.dayRange(
            DateTime(2026, 10, 22),
            DateTime(2026, 10, 25),
            short: true,
          ),
          '22–25 окт',
        );
      });

      test('on the same day shows a single date', () {
        expect(
          DateFormatter.dayRange(
            DateTime(2026, 10, 22, 9),
            DateTime(2026, 10, 22, 18),
          ),
          '22 октября',
        );
      });

      test('across months shows both months', () {
        expect(
          DateFormatter.dayRange(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
          '30 сентября – 2 октября',
        );
        expect(
          DateFormatter.dayRange(
            DateTime(2026, 9, 30),
            DateTime(2026, 10, 2),
            short: true,
          ),
          '30 сен – 2 окт',
        );
      });

      test('across years omits the years', () {
        expect(
          DateFormatter.dayRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
          '30 декабря – 2 января',
        );
      });

      test('the same month in different years is not merged', () {
        expect(
          DateFormatter.dayRange(DateTime(2026, 10, 1), DateTime(2027, 10, 5)),
          '1 октября – 5 октября',
        );
      });
    });

    group('relativeDayTime', () {
      final DateTime now = DateTime(2026, 10, 22, 10);

      test('today, yesterday and tomorrow use words', () {
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 10, 22, 9, 38),
            now: now,
          ),
          'сегодня, 09:38',
        );
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 10, 21, 18, 10),
            now: now,
          ),
          'вчера, 18:10',
        );
        expect(
          DateFormatter.relativeDayTime(DateTime(2026, 10, 23, 12), now: now),
          'завтра, 12:00',
        );
      });

      test('compares calendar days, not 24-hour periods', () {
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 10, 21, 23, 59),
            now: DateTime(2026, 10, 22, 0, 1),
          ),
          'вчера, 23:59',
        );
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 10, 22, 0, 1),
            now: DateTime(2026, 10, 22, 23, 59),
          ),
          'сегодня, 00:01',
        );
      });

      test('handles month and year boundaries', () {
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 12, 31, 20),
            now: DateTime(2027, 1, 1, 8),
          ),
          'вчера, 20:00',
        );
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 11, 1, 8),
            now: DateTime(2026, 10, 31, 22),
          ),
          'завтра, 08:00',
        );
      });

      test('other days show the date', () {
        expect(
          DateFormatter.relativeDayTime(
            DateTime(2026, 10, 20, 9, 38),
            now: now,
          ),
          '20 октября, 09:38',
        );
        expect(
          DateFormatter.relativeDayTime(DateTime(2026, 10, 24, 7), now: now),
          '24 октября, 07:00',
        );
      });
    });

    group('countdown', () {
      test('formats minutes and seconds', () {
        expect(DateFormatter.countdown(const Duration(seconds: 28)), '00:28');
        expect(DateFormatter.countdown(const Duration(seconds: 90)), '01:30');
        expect(DateFormatter.countdown(Duration.zero), '00:00');
      });

      test('keeps counting minutes past an hour', () {
        expect(
          DateFormatter.countdown(const Duration(hours: 1, seconds: 5)),
          '60:05',
        );
      });

      test('clamps a negative duration to zero', () {
        expect(DateFormatter.countdown(const Duration(seconds: -3)), '00:00');
      });

      test('drops sub-second precision', () {
        expect(
          DateFormatter.countdown(
            const Duration(seconds: 5, milliseconds: 999),
          ),
          '00:05',
        );
      });
    });
  });
}
