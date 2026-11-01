import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/notifications/domain/entity/mark_notification_read_params_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_filter.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

final class NotificationsBloc
    extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this._getNotifications,
    required this._markNotificationRead,
    required this._markAllNotificationsRead,
  }) : super(const NotificationsState()) {
    // Latest wins: a refresh replaces a load that is still running.
    on<NotificationsRequested>(_onRequested, transformer: restartable());
    on<NotificationsFilterSelected>(_onFilterSelected);
    on<NotificationOpened>(_onOpened);
    on<NotificationsAllReadRequested>(
      _onAllReadRequested,
      transformer: droppable(),
    );
  }

  final GetNotificationsUsecase _getNotifications;
  final MarkNotificationReadUsecase _markNotificationRead;
  final MarkAllNotificationsReadUsecase _markAllNotificationsRead;

  /// Keeps the shown feed while loading and after a failed refresh.
  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, NotificationFeedEntity> result =
        await _getNotifications(const NoParams());
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, NotificationFeedEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, NotificationFeedEntity>(
        value: final NotificationFeedEntity feed,
      ):
        emit(state.copyWith(loadStatus: RequestStatus.success, feed: feed));
    }
  }

  void _onFilterSelected(
    NotificationsFilterSelected event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  /// The screen navigates on tap; this only marks an unread notification
  /// read. The feed changes after the source confirmed the write.
  Future<void> _onOpened(
    NotificationOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final bool isUnread =
        state.feed?.notifications.any(
          (NotificationEntity notification) =>
              notification.id == event.id && !notification.isRead,
        ) ??
        false;
    if (!isUnread) {
      return;
    }
    emit(state.copyWith(resetActionFailure: true));

    final Either<Failure, void> result = await _markNotificationRead(
      MarkNotificationReadParamsEntity(id: event.id),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(state.copyWith(actionFailure: failure));
      case Right<Failure, void>():
        emit(state.copyWith(feed: state.feed?.withRead(<String>{event.id})));
    }
  }

  Future<void> _onAllReadRequested(
    NotificationsAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!state.canMarkAllRead) {
      return;
    }
    emit(
      state.copyWith(
        markAllStatus: RequestStatus.loading,
        resetActionFailure: true,
      ),
    );

    final Either<Failure, void> result = await _markAllNotificationsRead(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(
          state.copyWith(
            markAllStatus: RequestStatus.failure,
            actionFailure: failure,
          ),
        );
      case Right<Failure, void>():
        final NotificationFeedEntity? feed = state.feed;
        emit(
          state.copyWith(
            markAllStatus: RequestStatus.success,
            feed: feed?.withRead(<String>{
              for (final NotificationEntity notification in feed.notifications)
                notification.id,
            }),
          ),
        );
    }
  }
}
