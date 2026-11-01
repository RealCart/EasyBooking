import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';

/// The chips above the notification list.
enum NotificationFilter {
  all,
  important,
  contracts;

  bool matches(NotificationEntity notification) {
    return switch (this) {
      NotificationFilter.all => true,
      NotificationFilter.important => notification.kind.isImportant,
      NotificationFilter.contracts => notification.kind.isContract,
    };
  }
}
