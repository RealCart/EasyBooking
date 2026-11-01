part of 'properties_bloc.dart';

sealed class PropertiesEvent extends Equatable {
  const PropertiesEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the list: added when the BLoC is created, on retry, on
/// pull-to-refresh, and after returning from a property.
final class PropertiesRequested extends PropertiesEvent {
  const PropertiesRequested();
}

final class PropertiesFilterSelected extends PropertiesEvent {
  const PropertiesFilterSelected(this.filter);

  final PropertiesFilter filter;

  @override
  List<Object?> get props => <Object?>[filter];
}

/// The search text changed; the loaded list is filtered locally.
final class PropertiesQueryChanged extends PropertiesEvent {
  const PropertiesQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class PropertiesSortSelected extends PropertiesEvent {
  const PropertiesSortSelected(this.sort);

  final PropertySort sort;

  @override
  List<Object?> get props => <Object?>[sort];
}

/// The user tapped the heart of [propertyId].
final class PropertyFavoriteToggled extends PropertiesEvent {
  const PropertyFavoriteToggled(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => <Object?>[propertyId];
}
