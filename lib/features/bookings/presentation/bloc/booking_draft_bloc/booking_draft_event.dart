part of 'booking_draft_bloc.dart';

sealed class BookingDraftEvent extends Equatable {
  const BookingDraftEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the apartments and the saved draft: added when the BLoC is created
/// and on retry.
final class BookingDraftStarted extends BookingDraftEvent {
  const BookingDraftStarted();
}

/// The text of «Найти существующего гостя» changed. Debounced; a blank
/// [query] clears the results.
final class BookingDraftGuestSearched extends BookingDraftEvent {
  const BookingDraftGuestSearched(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// The user edited the form field [field] (a `BookingFields` key).
final class BookingDraftFieldEdited extends BookingDraftEvent {
  const BookingDraftFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// The validated form asked to continue to step 2 («Продолжить»).
final class BookingDraftSubmitted extends BookingDraftEvent {
  const BookingDraftSubmitted(this.params);

  final SaveBookingDraftParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
