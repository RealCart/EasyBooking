part of 'booking_draft_bloc.dart';

final class BookingDraftState extends Equatable {
  const BookingDraftState({
    this.loadStatus = RequestStatus.initial,
    this.properties = const <PropertyEntity>[],
    this.draft,
    this.today,
    this.loadFailure,
    this.guestQuery = '',
    this.guestSearchStatus = RequestStatus.initial,
    this.guests = const <BookingGuestEntity>[],
    this.guestSearchFailure,
    this.submitStatus = RequestStatus.initial,
    this.submitFailure,
    this.fieldErrors = const <String, String>{},
  });

  /// Status of loading [properties] and [draft].
  final RequestStatus loadStatus;

  /// Options of the «Квартира» picker.
  final List<PropertyEntity> properties;

  /// The saved draft: on load, the values to prefill the form with
  /// (`null` when there is none); after a submit, the draft just saved.
  final BookingDraftEntity? draft;

  /// The source's today from the load, at midnight: the reference for the
  /// default dates and the earliest check-in. `null` until loaded.
  final DateTime? today;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The trimmed query [guests] belong to; empty when nothing is searched.
  final String guestQuery;
  final RequestStatus guestSearchStatus;

  /// Earlier guests matching [guestQuery]; picking one fills the guest
  /// fields.
  final List<BookingGuestEntity> guests;

  /// Set when [guestSearchStatus] is [RequestStatus.failure].
  final Failure? guestSearchFailure;

  /// Status of saving the draft; on success the screen opens step 2.
  final RequestStatus submitStatus;

  /// A failure that does not belong to a single field.
  final Failure? submitFailure;

  /// `BookingFields` key to a `BookingErrorCodes` field code.
  final Map<String, String> fieldErrors;

  BookingDraftState copyWith({
    RequestStatus? loadStatus,
    List<PropertyEntity>? properties,
    BookingDraftEntity? draft,
    bool resetDraft = false,
    DateTime? today,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    String? guestQuery,
    RequestStatus? guestSearchStatus,
    List<BookingGuestEntity>? guests,
    Failure? guestSearchFailure,
    bool resetGuestSearchFailure = false,
    RequestStatus? submitStatus,
    Failure? submitFailure,
    bool resetSubmitFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return BookingDraftState(
      loadStatus: loadStatus ?? this.loadStatus,
      properties: properties ?? this.properties,
      draft: resetDraft ? null : draft ?? this.draft,
      today: today ?? this.today,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      guestQuery: guestQuery ?? this.guestQuery,
      guestSearchStatus: guestSearchStatus ?? this.guestSearchStatus,
      guests: guests ?? this.guests,
      guestSearchFailure: resetGuestSearchFailure
          ? null
          : guestSearchFailure ?? this.guestSearchFailure,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: resetSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    properties,
    draft,
    today,
    loadFailure,
    guestQuery,
    guestSearchStatus,
    guests,
    guestSearchFailure,
    submitStatus,
    submitFailure,
    fieldErrors,
  ];
}
