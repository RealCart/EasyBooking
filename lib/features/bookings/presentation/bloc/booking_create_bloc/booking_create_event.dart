part of 'booking_create_bloc.dart';

sealed class BookingCreateEvent extends Equatable {
  const BookingCreateEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the draft saved on step 1: added when the BLoC is created and on
/// retry.
final class BookingCreateStarted extends BookingCreateEvent {
  const BookingCreateStarted();
}

/// The user edited the form field [field] (a `BookingFields` key).
final class BookingCreateFieldEdited extends BookingCreateEvent {
  const BookingCreateFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// The validated form asked to create the booking («Создать бронь»).
final class BookingCreateSubmitted extends BookingCreateEvent {
  const BookingCreateSubmitted(this.params);

  final CreateBookingParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
