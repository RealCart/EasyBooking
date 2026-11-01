part of 'property_detail_bloc.dart';

sealed class PropertyDetailEvent extends Equatable {
  const PropertyDetailEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [propertyId]: added when the BLoC is created and on retry.
final class PropertyDetailRequested extends PropertyDetailEvent {
  const PropertyDetailRequested(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => <Object?>[propertyId];
}

final class PropertyDetailFavoriteToggled extends PropertyDetailEvent {
  const PropertyDetailFavoriteToggled();
}
