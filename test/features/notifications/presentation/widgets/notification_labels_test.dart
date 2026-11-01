import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/notifications/presentation/widgets/notification_labels.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 22, 9, 41);

  group('NotificationTimeLabels.createdAt', () {
    String label(Duration age) {
      return NotificationTimeLabels.createdAt(now.subtract(age), now: now);
    }

    test('under a minute is now', () {
      expect(label(const Duration(seconds: 30)), 'сейчас');
    });

    test('under an hour counts minutes', () {
      expect(label(const Duration(minutes: 2)), '2 мин');
      expect(label(const Duration(minutes: 59)), '59 мин');
    });

    test('under three hours counts hours', () {
      expect(label(const Duration(hours: 1, minutes: 10)), '1 ч');
    });

    test('older shows the time of day', () {
      expect(label(const Duration(hours: 3)), '06:41');
    });
  });

  group('NotificationTimeLabels.day', () {
    test('names today and yesterday, otherwise the date', () {
      expect(
        NotificationTimeLabels.day(DateTime(2026, 10, 22, 1), now: now),
        'Сегодня',
      );
      expect(
        NotificationTimeLabels.day(DateTime(2026, 10, 21, 23), now: now),
        'Вчера',
      );
      expect(
        NotificationTimeLabels.day(DateTime(2026, 10, 20, 12), now: now),
        '20 октября',
      );
    });
  });
}
