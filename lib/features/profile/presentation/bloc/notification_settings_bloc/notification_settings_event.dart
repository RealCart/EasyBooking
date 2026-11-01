part of 'notification_settings_bloc.dart';

sealed class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the saved settings: added when the BLoC is created and on retry.
final class NotificationSettingsRequested extends NotificationSettingsEvent {
  const NotificationSettingsRequested();
}

/// «Сохранить настройки» with every toggle and channel of the screen.
final class NotificationSettingsSubmitted extends NotificationSettingsEvent {
  const NotificationSettingsSubmitted(this.params);

  final UpdateNotificationSettingsParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
