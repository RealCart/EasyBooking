import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';

final class NotificationFeedEntity extends Equatable {
  const NotificationFeedEntity({
    required this.notifications,
    required this.receivedAt,
  });

  final List<NotificationEntity> notifications;
  final DateTime receivedAt;

  int get unreadCount {
    return notifications
        .where((NotificationEntity notification) => !notification.isRead)
        .length;
  }

  NotificationFeedEntity withRead(Set<String> ids) {
    return NotificationFeedEntity(
      notifications: List<NotificationEntity>.unmodifiable(
        notifications.map(
          (NotificationEntity notification) => ids.contains(notification.id)
              ? notification.asRead()
              : notification,
        ),
      ),
      receivedAt: receivedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[notifications, receivedAt];
}
