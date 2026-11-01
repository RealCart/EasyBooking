part of 'property_bookings_bloc.dart';

sealed class PropertyBookingsEvent extends Equatable {
  const PropertyBookingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the bookings of [propertyId]: added when the BLoC is created, on
/// retry, and after returning from a booking.
final class PropertyBookingsRequested extends PropertyBookingsEvent {
  const PropertyBookingsRequested(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => <Object?>[propertyId];
}

/// The user tapped «Предстоящие» or «Прошедшие».
final class PropertyBookingsPeriodSelected extends PropertyBookingsEvent {
  const PropertyBookingsPeriodSelected(this.period);

  final PropertyBookingsPeriod period;

  @override
  List<Object?> get props => <Object?>[period];
}
