import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/data/sources/local/notifications_mock_local.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';

void main() {
  group('NotificationsMockLocalImpl', () {
    final DateTime now = DateTime(2026, 10, 22, 9, 41);
    late NotificationsMockLocalImpl local;

    setUp(() {
      local = NotificationsMockLocalImpl(now: () => now);
    });

    Future<NotificationFeedEntity> load() async {
      final Either<Failure, NotificationFeedEntity> result = await local
          .loadFeed();
      return result.fold(
        (Failure failure) => fail('Unexpected failure $failure'),
        (NotificationFeedEntity feed) => feed,
      );
    }

    test('the feed is newest first and stamped with the clock', () async {
      final NotificationFeedEntity feed = await load();

      expect(feed.receivedAt, now);
      expect(feed.notifications, hasLength(6));
      for (int index = 1; index < feed.notifications.length; index++) {
        expect(
          feed.notifications[index].createdAt.isBefore(
            feed.notifications[index - 1].createdAt,
          ),
          isTrue,
        );
      }
    });

    test('only the failed sync starts unread', () async {
      final NotificationFeedEntity feed = await load();

      expect(feed.unreadCount, 1);
      expect(
        feed.notifications
            .singleWhere((NotificationEntity item) => !item.isRead)
            .kind,
        NotificationKind.syncFailed,
      );
    });

    test('a marked notification stays read in later feeds', () async {
      final NotificationEntity unread = (await load()).notifications
          .singleWhere((NotificationEntity item) => !item.isRead);

      final Either<Failure, void> result = await local.markRead(unread.id);

      expect(result.isRight, isTrue);
      expect((await load()).unreadCount, 0);
    });

    test('marking an unknown id fails with 404 and changes nothing', () async {
      final Either<Failure, void> result = await local.markRead('missing');

      expect(
        result,
        isA<Left<Failure, void>>().having(
          (Left<Failure, void> left) => left.value,
          'value',
          isA<ServerFailure>().having(
            (ServerFailure failure) => failure.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      expect((await load()).unreadCount, 1);
    });

    test('marking all read leaves nothing unread', () async {
      await local.markAllRead();

      expect((await load()).unreadCount, 0);
    });
  });
}
