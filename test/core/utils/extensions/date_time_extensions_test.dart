import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';

void main() {
  group('DateTimeExtensions.dateOnly', () {
    test('returns local midnight of the same day', () {
      final DateTime value = DateTime(2026, 10, 22, 18, 30, 15, 500);

      expect(value.dateOnly, DateTime(2026, 10, 22));
      expect(value.dateOnly.isUtc, isFalse);
    });

    test('keeps UTC dates in UTC', () {
      final DateTime value = DateTime.utc(2026, 10, 22, 23, 59);

      expect(value.dateOnly, DateTime.utc(2026, 10, 22));
      expect(value.dateOnly.isUtc, isTrue);
    });
  });

  group('DateTimeExtensions.isSameDay', () {
    test('ignores the time of day', () {
      expect(
        DateTime(2026, 10, 22, 0, 1).isSameDay(DateTime(2026, 10, 22, 23, 59)),
        isTrue,
      );
    });

    test('compares year, month and day', () {
      final DateTime value = DateTime(2026, 10, 22);

      expect(value.isSameDay(DateTime(2026, 10, 23)), isFalse);
      expect(value.isSameDay(DateTime(2026, 11, 22)), isFalse);
      expect(value.isSameDay(DateTime(2025, 10, 22)), isFalse);
    });
  });

  group('DateTimeExtensions.addDays', () {
    test('keeps the full time of day', () {
      final DateTime value = DateTime(2026, 10, 22, 14, 30, 15, 250, 125);

      expect(value.addDays(1), DateTime(2026, 10, 23, 14, 30, 15, 250, 125));
    });

    test('rolls over month and year ends', () {
      expect(DateTime(2026, 10, 31, 9).addDays(1), DateTime(2026, 11, 1, 9));
      expect(DateTime(2026, 12, 31).addDays(1), DateTime(2027, 1, 1));
      expect(DateTime(2028, 2, 28).addDays(1), DateTime(2028, 2, 29));
    });

    test('supports negative and zero offsets', () {
      expect(DateTime(2026, 3, 1, 8).addDays(-1), DateTime(2026, 2, 28, 8));
      expect(DateTime(2026, 3, 1, 8).addDays(0), DateTime(2026, 3, 1, 8));
    });

    test('keeps UTC dates in UTC', () {
      final DateTime result = DateTime.utc(2026, 10, 22, 6).addDays(2);

      expect(result, DateTime.utc(2026, 10, 24, 6));
      expect(result.isUtc, isTrue);
    });
  });

  group('DateTimeExtensions.startOfWeek', () {
    test('returns Monday midnight for every day of the week', () {
      // 19 October 2026 is a Monday.
      for (int offset = 0; offset < 7; offset++) {
        final DateTime day = DateTime(2026, 10, 19 + offset, 15, 45);

        expect(day.startOfWeek, DateTime(2026, 10, 19), reason: '$day');
      }
    });

    test('crosses a month boundary', () {
      // 1 November 2026 is a Sunday.
      expect(DateTime(2026, 11, 1).startOfWeek, DateTime(2026, 10, 26));
    });
  });

  group('DateTimeExtensions.nightsUntil', () {
    test('counts calendar nights regardless of time', () {
      expect(
        DateTime(2026, 10, 22, 14).nightsUntil(DateTime(2026, 10, 25, 12)),
        3,
      );
      expect(
        DateTime(2026, 10, 22, 23).nightsUntil(DateTime(2026, 10, 23, 1)),
        1,
      );
    });

    test('is zero on the same day and negative when reversed', () {
      expect(DateTime(2026, 10, 22).nightsUntil(DateTime(2026, 10, 22, 20)), 0);
      expect(DateTime(2026, 10, 25).nightsUntil(DateTime(2026, 10, 22)), -3);
    });

    test('crosses month and year ends', () {
      expect(DateTime(2026, 12, 30).nightsUntil(DateTime(2027, 1, 2)), 3);
    });
  });
}
