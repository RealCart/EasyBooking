part of 'property_settings_bloc.dart';

sealed class PropertySettingsEvent extends Equatable {
  const PropertySettingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the settings of [propertyId]: added when the BLoC is created and
/// on retry.
final class PropertySettingsRequested extends PropertySettingsEvent {
  const PropertySettingsRequested(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => <Object?>[propertyId];
}

/// «Сохранить изменения» with the values the screen holds.
final class PropertySettingsSubmitted extends PropertySettingsEvent {
  const PropertySettingsSubmitted(this.params);

  final SavePropertySettingsParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
