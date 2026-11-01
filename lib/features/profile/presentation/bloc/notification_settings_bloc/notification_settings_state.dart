part of 'notification_settings_bloc.dart';

final class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.loadStatus = RequestStatus.initial,
    this.settings,
    this.loadFailure,
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
  });

  final RequestStatus loadStatus;

  /// The saved settings: the loaded ones, replaced after every save. The
  /// screen starts its toggles from them.
  final NotificationSettingsEntity? settings;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus saveStatus;

  /// Set when [saveStatus] is [RequestStatus.failure]; a
  /// `ValidationFailure` with `ProfileErrorCodes.noDeliveryChannel` means
  /// no delivery channel was selected.
  final Failure? saveFailure;

  NotificationSettingsState copyWith({
    RequestStatus? loadStatus,
    NotificationSettingsEntity? settings,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool resetSaveFailure = false,
  }) {
    return NotificationSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      settings: settings ?? this.settings,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: resetSaveFailure ? null : saveFailure ?? this.saveFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    settings,
    loadFailure,
    saveStatus,
    saveFailure,
  ];
}
