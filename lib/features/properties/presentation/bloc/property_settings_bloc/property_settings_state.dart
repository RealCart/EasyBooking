part of 'property_settings_bloc.dart';

final class PropertySettingsState extends Equatable {
  const PropertySettingsState({
    this.propertyId = '',
    this.loadStatus = RequestStatus.initial,
    this.settings,
    this.loadFailure,
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
  });

  /// The requested property, for retrying a failed load.
  final String propertyId;

  final RequestStatus loadStatus;

  /// The settings as stored; replaced after a successful save.
  final PropertySettingsEntity? settings;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// Status of the last save, independent of [loadStatus].
  final RequestStatus saveStatus;

  /// Set when [saveStatus] is [RequestStatus.failure].
  final Failure? saveFailure;

  PropertySettingsState copyWith({
    String? propertyId,
    RequestStatus? loadStatus,
    PropertySettingsEntity? settings,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool resetSaveFailure = false,
  }) {
    return PropertySettingsState(
      propertyId: propertyId ?? this.propertyId,
      loadStatus: loadStatus ?? this.loadStatus,
      settings: settings ?? this.settings,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: resetSaveFailure ? null : saveFailure ?? this.saveFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    loadStatus,
    settings,
    loadFailure,
    saveStatus,
    saveFailure,
  ];
}
