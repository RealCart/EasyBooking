import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_filter.dart';

extension NotificationFilterLabels on NotificationFilter {
  String get label {
    return switch (this) {
      NotificationFilter.all => 'Все',
      NotificationFilter.important => 'Важные',
      NotificationFilter.contracts => 'Договоры',
    };
  }

  String get emptyTitle {
    return switch (this) {
      NotificationFilter.all => 'Уведомлений пока нет',
      NotificationFilter.important => 'Важных уведомлений нет',
      NotificationFilter.contracts => 'Уведомлений о договорах нет',
    };
  }
}

abstract final class NotificationTimeLabels {
  /// `сейчас`, `2 мин`, `1 ч` within three hours of [now], otherwise the
  /// time of day (`09:00`); the day is shown by the group header.
  static String createdAt(DateTime createdAt, {required DateTime now}) {
    final Duration age = now.difference(createdAt);
    if (age < const Duration(minutes: 1)) {
      return 'сейчас';
    }
    if (age < const Duration(hours: 1)) {
      return '${age.inMinutes} мин';
    }
    if (age < const Duration(hours: 3)) {
      return '${age.inHours} ч';
    }
    return DateFormatter.time(createdAt);
  }

  /// `Сегодня`, `Вчера`, otherwise `20 октября`.
  static String day(DateTime date, {required DateTime now}) {
    final int dayDifference = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return switch (dayDifference) {
      0 => 'Сегодня',
      -1 => 'Вчера',
      _ => DateFormatter.dayMonth(date),
    };
  }
}
