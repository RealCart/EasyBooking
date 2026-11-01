part of 'booking_create_bloc.dart';

final class BookingCreateState extends Equatable {
  const BookingCreateState({
    this.loadStatus = RequestStatus.initial,
    this.draft,
    this.loadFailure,
    this.submitStatus = RequestStatus.initial,
    this.submitFailure,
    this.fieldErrors = const <String, String>{},
    this.createdBookingId,
  });

  /// Status of loading [draft].
  final RequestStatus loadStatus;

  /// The draft of step 1. `null` after a successful load means there is no
  /// draft (for example, it was already turned into a booking): the screen
  /// goes back to step 1.
  final BookingDraftEntity? draft;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// Status of creating the booking.
  final RequestStatus submitStatus;

  /// A failure that does not belong to a single field, such as a
  /// `ValidationFailure` coded `BookingErrorCodes.datesUnavailable`.
  final Failure? submitFailure;

  /// `BookingFields` key to a `BookingErrorCodes` field code.
  final Map<String, String> fieldErrors;

  /// The new booking, set when [submitStatus] is [RequestStatus.success].
  final String? createdBookingId;

  BookingCreateState copyWith({
    RequestStatus? loadStatus,
    BookingDraftEntity? draft,
    bool resetDraft = false,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? submitStatus,
    Failure? submitFailure,
    bool resetSubmitFailure = false,
    Map<String, String>? fieldErrors,
    String? createdBookingId,
  }) {
    return BookingCreateState(
      loadStatus: loadStatus ?? this.loadStatus,
      draft: resetDraft ? null : draft ?? this.draft,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: resetSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      createdBookingId: createdBookingId ?? this.createdBookingId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    draft,
    loadFailure,
    submitStatus,
    submitFailure,
    fieldErrors,
    createdBookingId,
  ];
}
