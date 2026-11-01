import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/notifications/domain/entity/mark_notification_read_params_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';

import '../../../../helpers/fake_notifications_repository.dart';

const Failure _failure = ConnectionFailure();

void main() {
  late FakeNotificationsRepository repository;

  setUp(() {
    repository = FakeNotificationsRepository();
  });

  group('GetNotificationsUsecase', () {
    test('returns the feed and passes a failure through', () async {
      final GetNotificationsUsecase usecase = GetNotificationsUsecase(
        repository,
      );

      expect(
        await usecase(const NoParams()),
        Right<Failure, NotificationFeedEntity>(testNotificationFeed()),
      );

      repository.feedResult = const Left<Failure, NotificationFeedEntity>(
        _failure,
      );
      expect(
        await usecase(const NoParams()),
        const Left<Failure, NotificationFeedEntity>(_failure),
      );
    });
  });

  group('MarkNotificationReadUsecase', () {
    test('forwards the id of the params', () async {
      await MarkNotificationReadUsecase(
        repository,
      )(const MarkNotificationReadParamsEntity(id: 'n1'));

      expect(repository.markedReadIds, <String>['n1']);
    });

    test('passes a failure through unchanged', () async {
      repository.markReadResult = const Left<Failure, void>(_failure);

      expect(
        await MarkNotificationReadUsecase(
          repository,
        )(const MarkNotificationReadParamsEntity(id: 'n1')),
        const Left<Failure, void>(_failure),
      );
    });
  });

  group('MarkAllNotificationsReadUsecase', () {
    test('delegates and passes a failure through', () async {
      repository.markAllReadResult = const Left<Failure, void>(_failure);

      final Either<Failure, void> result =
          await MarkAllNotificationsReadUsecase(
            repository,
          )(const NoParams());

      expect(repository.markAllReadCount, 1);
      expect(result, const Left<Failure, void>(_failure));
    });
  });
}
