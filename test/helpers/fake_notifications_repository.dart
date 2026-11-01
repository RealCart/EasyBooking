import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';

final DateTime notificationsTestNow = DateTime(2026, 10, 22, 9, 41);

/// A feed for tests: an unread failed sync and a read signed contract today,
/// and a read published property yesterday.
NotificationFeedEntity testNotificationFeed() {
  return NotificationFeedEntity(
    receivedAt: notificationsTestNow,
    notifications: <NotificationEntity>[
      NotificationEntity(
        id: 'sync',
        kind: NotificationKind.syncFailed,
        title: 'Airbnb не обновился',
        body: 'Проверьте iCal-ссылку.',
        createdAt: notificationsTestNow.subtract(const Duration(minutes: 21)),
        targetId: 'p1',
        isRead: false,
      ),
      NotificationEntity(
        id: 'signed',
        kind: NotificationKind.contractSigned,
        title: 'Договор подписан',
        body: 'Асель подписала договор.',
        createdAt: notificationsTestNow.subtract(const Duration(hours: 1)),
        targetId: 'c1',
        isRead: true,
      ),
      NotificationEntity(
        id: 'published',
        kind: NotificationKind.propertyPublished,
        title: 'Объект опубликован',
        body: 'Al-Farabi Residence готова.',
        createdAt: DateTime(2026, 10, 21, 18, 42),
        targetId: 'p2',
        isRead: true,
      ),
    ],
  );
}

/// [NotificationsRepository] that records calls and answers with the
/// configured results.
///
/// Set [holdFeed] to keep the next feed requests pending; each gets a
/// completer in [heldFeeds].
final class FakeNotificationsRepository implements NotificationsRepository {
  Either<Failure, NotificationFeedEntity> feedResult =
      Right<Failure, NotificationFeedEntity>(testNotificationFeed());
  Either<Failure, void> markReadResult = const Right<Failure, void>(null);
  Either<Failure, void> markAllReadResult = const Right<Failure, void>(null);

  bool holdFeed = false;
  final List<Completer<Either<Failure, NotificationFeedEntity>>> heldFeeds =
      <Completer<Either<Failure, NotificationFeedEntity>>>[];

  int feedCount = 0;
  final List<String> markedReadIds = <String>[];
  int markAllReadCount = 0;

  @override
  Future<Either<Failure, NotificationFeedEntity>> getFeed() async {
    feedCount += 1;
    if (!holdFeed) {
      return feedResult;
    }
    final Completer<Either<Failure, NotificationFeedEntity>> completer =
        Completer<Either<Failure, NotificationFeedEntity>>();
    heldFeeds.add(completer);
    return completer.future;
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    markedReadIds.add(id);
    return markReadResult;
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    markAllReadCount += 1;
    return markAllReadResult;
  }
}
