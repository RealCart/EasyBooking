import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_filter.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:easy_booking/features/notifications/presentation/bloc/notifications_bloc/notifications_bloc.dart';

import '../../../../../helpers/fake_notifications_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [NotificationsBloc] over a [FakeNotificationsRepository] that records
/// its states.
final class _Subject {
  _Subject() {
    bloc = NotificationsBloc(
      getNotifications: GetNotificationsUsecase(repository),
      markNotificationRead: MarkNotificationReadUsecase(repository),
      markAllNotificationsRead: MarkAllNotificationsReadUsecase(repository),
    );
    final StreamSubscription<NotificationsState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeNotificationsRepository repository = FakeNotificationsRepository();
  late final NotificationsBloc bloc;
  final List<NotificationsState> states = <NotificationsState>[];

  Future<void> add(NotificationsEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> loaded() async {
    await add(const NotificationsRequested());
    states.clear();
  }

  NotificationEntity notification(String id) {
    return bloc.state.feed!.notifications.singleWhere(
      (NotificationEntity notification) => notification.id == id,
    );
  }
}

void main() {
  group('NotificationsBloc', () {
    test('starts with nothing loaded and the all filter', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const NotificationsState());
      expect(subject.bloc.state.visibleNotifications, isEmpty);
      expect(subject.bloc.state.canMarkAllRead, isFalse);
    });

    test('a load emits loading, then the feed', () async {
      final _Subject subject = _Subject();

      await subject.add(const NotificationsRequested());

      expect(subject.states, <NotificationsState>[
        const NotificationsState(loadStatus: RequestStatus.loading),
        NotificationsState(
          loadStatus: RequestStatus.success,
          feed: testNotificationFeed(),
        ),
      ]);
      expect(subject.bloc.state.canMarkAllRead, isTrue);
    });

    test('a failed load emits the failure without a feed', () async {
      final _Subject subject = _Subject();
      subject.repository.feedResult =
          const Left<Failure, NotificationFeedEntity>(_failure);

      await subject.add(const NotificationsRequested());

      expect(
        subject.states.last,
        const NotificationsState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      );
    });

    test('a failed refresh keeps the feed', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.feedResult =
          const Left<Failure, NotificationFeedEntity>(_failure);

      await subject.add(const NotificationsRequested());

      expect(subject.bloc.state.feed, testNotificationFeed());
      expect(subject.bloc.state.loadFailure, _failure);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdFeed = true;
      final NotificationFeedEntity older = NotificationFeedEntity(
        notifications: const <NotificationEntity>[],
        receivedAt: DateTime(2026),
      );

      await subject.add(const NotificationsRequested());
      await subject.add(const NotificationsRequested());
      subject.repository.heldFeeds[1].complete(
        Right<Failure, NotificationFeedEntity>(testNotificationFeed()),
      );
      await pumpEventQueue();
      subject.repository.heldFeeds[0].complete(
        Right<Failure, NotificationFeedEntity>(older),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.feed, testNotificationFeed());
    });

    test('a filter shows only its notifications', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(
        const NotificationsFilterSelected(NotificationFilter.contracts),
      );

      expect(subject.bloc.state.filter, NotificationFilter.contracts);
      expect(
        subject.bloc.state.visibleNotifications.map(
          (NotificationEntity notification) => notification.id,
        ),
        <String>['signed'],
      );
    });

    test('opening an unread notification marks it read', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const NotificationOpened('sync'));

      expect(subject.repository.markedReadIds, <String>['sync']);
      expect(subject.notification('sync').isRead, isTrue);
      expect(subject.bloc.state.canMarkAllRead, isFalse);
    });

    test('opening a read notification writes nothing', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const NotificationOpened('signed'));

      expect(subject.repository.markedReadIds, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('a failed mark keeps it unread and reports the failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.markReadResult = const Left<Failure, void>(_failure);

      await subject.add(const NotificationOpened('sync'));

      expect(subject.notification('sync').isRead, isFalse);
      expect(subject.bloc.state.actionFailure, _failure);
    });

    test('the next action clears an earlier action failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.markReadResult = const Left<Failure, void>(_failure);
      await subject.add(const NotificationOpened('sync'));
      subject.repository.markReadResult = const Right<Failure, void>(null);

      await subject.add(const NotificationOpened('sync'));

      expect(subject.bloc.state.actionFailure, isNull);
      expect(subject.notification('sync').isRead, isTrue);
    });

    test('mark all read marks every notification read', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const NotificationsAllReadRequested());

      expect(subject.repository.markAllReadCount, 1);
      expect(subject.bloc.state.feed!.unreadCount, 0);
      expect(subject.bloc.state.markAllStatus, RequestStatus.success);
      expect(subject.bloc.state.canMarkAllRead, isFalse);
    });

    test('mark all read does nothing when everything is read', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      await subject.add(const NotificationsAllReadRequested());

      await subject.add(const NotificationsAllReadRequested());

      expect(subject.repository.markAllReadCount, 1);
    });

    test('a failed mark all read keeps the feed and reports it', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.markAllReadResult = const Left<Failure, void>(
        _failure,
      );

      await subject.add(const NotificationsAllReadRequested());

      expect(subject.bloc.state.feed, testNotificationFeed());
      expect(subject.bloc.state.markAllStatus, RequestStatus.failure);
      expect(subject.bloc.state.actionFailure, _failure);
    });

    test('a load that completes after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdFeed = true;
      await subject.add(const NotificationsRequested());
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldFeeds.single.complete(
        Right<Failure, NotificationFeedEntity>(testNotificationFeed()),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
    });
  });
}
