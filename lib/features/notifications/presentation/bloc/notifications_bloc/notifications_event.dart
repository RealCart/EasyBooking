part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the feed: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

final class NotificationsFilterSelected extends NotificationsEvent {
  const NotificationsFilterSelected(this.filter);

  final NotificationFilter filter;

  @override
  List<Object?> get props => <Object?>[filter];
}

/// The user opened the notification [id]; marks it read.
final class NotificationOpened extends NotificationsEvent {
  const NotificationOpened(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// «Прочитать»: marks every notification read.
final class NotificationsAllReadRequested extends NotificationsEvent {
  const NotificationsAllReadRequested();
}
