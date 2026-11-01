import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/data/repository/notifications_repository_impl.dart';
import 'package:easy_booking/features/notifications/data/sources/local/notifications_mock_local.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';

import '../../../../helpers/fake_notifications_repository.dart';

const Failure _failure = StorageFailure(message: 'disk');

final class _FakeNotificationsMockLocal implements NotificationsMockLocal {
  Either<Failure, NotificationFeedEntity> feedResult =
      Right<Failure, NotificationFeedEntity>(testNotificationFeed());
  Either<Failure, void> writeResult = const Right<Failure, void>(null);
  final List<String> markedReadIds = <String>[];
  int markAllReadCount = 0;

  @override
  Future<Either<Failure, NotificationFeedEntity>> loadFeed() async {
    return feedResult;
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    markedReadIds.add(id);
    return writeResult;
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    markAllReadCount += 1;
    return writeResult;
  }
}

void main() {
  group('NotificationsRepositoryImpl', () {
    late _FakeNotificationsMockLocal local;
    late NotificationsRepositoryImpl repository;

    setUp(() {
      local = _FakeNotificationsMockLocal();
      repository = NotificationsRepositoryImpl(local: local);
    });

    test('getFeed returns the feed of the source', () async {
      expect(
        await repository.getFeed(),
        Right<Failure, NotificationFeedEntity>(testNotificationFeed()),
      );
    });

    test('getFeed passes a source failure through unchanged', () async {
      local.feedResult = const Left<Failure, NotificationFeedEntity>(_failure);

      expect(
        await repository.getFeed(),
        const Left<Failure, NotificationFeedEntity>(_failure),
      );
    });

    test('markRead forwards the id and passes a failure through', () async {
      local.writeResult = const Left<Failure, void>(_failure);

      final Either<Failure, void> result = await repository.markRead('n1');

      expect(local.markedReadIds, <String>['n1']);
      expect(result, const Left<Failure, void>(_failure));
    });

    test('markAllRead delegates to the source', () async {
      final Either<Failure, void> result = await repository.markAllRead();

      expect(local.markAllReadCount, 1);
      expect(result.isRight, isTrue);
    });
  });
}
