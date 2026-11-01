part of 'notifications_bloc.dart';

final class NotificationsState extends Equatable {
  const NotificationsState({
    this.loadStatus = RequestStatus.initial,
    this.feed,
    this.loadFailure,
    this.filter = NotificationFilter.all,
    this.markAllStatus = RequestStatus.initial,
    this.actionFailure,
  });

  final RequestStatus loadStatus;
  final NotificationFeedEntity? feed;
  final Failure? loadFailure;
  final NotificationFilter filter;
  final RequestStatus markAllStatus;
  final Failure? actionFailure;

  List<NotificationEntity> get visibleNotifications {
    if (feed == null) {
      return const <NotificationEntity>[];
    }
    return List<NotificationEntity>.unmodifiable(
      feed!.notifications.where(filter.matches),
    );
  }

  bool get canMarkAllRead {
    return (feed?.unreadCount ?? 0) > 0 && !markAllStatus.isLoading;
  }

  NotificationsState copyWith({
    RequestStatus? loadStatus,
    NotificationFeedEntity? feed,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    NotificationFilter? filter,
    RequestStatus? markAllStatus,
    Failure? actionFailure,
    bool resetActionFailure = false,
  }) {
    return NotificationsState(
      loadStatus: loadStatus ?? this.loadStatus,
      feed: feed ?? this.feed,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      filter: filter ?? this.filter,
      markAllStatus: markAllStatus ?? this.markAllStatus,
      actionFailure: resetActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    feed,
    loadFailure,
    filter,
    markAllStatus,
    actionFailure,
  ];
}
