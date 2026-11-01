import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_filter.dart';

import '../../../../helpers/fake_notifications_repository.dart';

void main() {
  group('NotificationFeedEntity', () {
    test('counts unread notifications', () {
      expect(testNotificationFeed().unreadCount, 1);
    });

    test('withRead marks only the given ids and keeps the time', () {
      final NotificationFeedEntity feed = testNotificationFeed();

      final NotificationFeedEntity updated = feed.withRead(<String>{'sync'});

      expect(updated.unreadCount, 0);
      expect(updated.receivedAt, feed.receivedAt);
      expect(updated.notifications[1], feed.notifications[1]);
      expect(updated.notifications.first.isRead, isTrue);
      expect(feed.notifications.first.isRead, isFalse);
    });
  });

  group('NotificationFilter.matches', () {
    final List<NotificationEntity> notifications =
        testNotificationFeed().notifications;

    List<String> idsFor(NotificationFilter filter) {
      return <String>[
        for (final NotificationEntity notification in notifications)
          if (filter.matches(notification)) notification.id,
      ];
    }

    test('all keeps everything', () {
      expect(idsFor(NotificationFilter.all), <String>[
        'sync',
        'signed',
        'published',
      ]);
    });

    test('important keeps conflicts and failed syncs', () {
      expect(idsFor(NotificationFilter.important), <String>['sync']);
    });

    test('contracts keeps contract notifications', () {
      expect(idsFor(NotificationFilter.contracts), <String>['signed']);
    });
  });
}
