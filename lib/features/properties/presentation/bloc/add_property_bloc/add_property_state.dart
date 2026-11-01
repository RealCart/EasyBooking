part of 'add_property_bloc.dart';

final class AddPropertyState extends Equatable {
  const AddPropertyState({
    this.draftStatus = RequestStatus.initial,
    this.draft,
    this.draftFailure,
    this.submitStatus = RequestStatus.initial,
    this.submitFailure,
    this.fieldErrors = const <String, String>{},
    this.publishedPropertyId,
  });

  /// Status of loading the draft for prefilling.
  final RequestStatus draftStatus;

  /// The draft as stored when the step opened.
  final AddPropertyDraftEntity? draft;

  /// Set when [draftStatus] is [RequestStatus.failure].
  final Failure? draftFailure;

  /// Status of this step's submit; on success the screen moves on.
  final RequestStatus submitStatus;

  /// A submit failure that does not belong to a single field.
  final Failure? submitFailure;

  /// `AddPropertyFields` key to a `PropertyErrorCodes` field code.
  final Map<String, String> fieldErrors;

  /// The id of the published property, after step 3 succeeded.
  final String? publishedPropertyId;

  AddPropertyState copyWith({
    RequestStatus? draftStatus,
    AddPropertyDraftEntity? draft,
    Failure? draftFailure,
    bool resetDraftFailure = false,
    RequestStatus? submitStatus,
    Failure? submitFailure,
    bool resetSubmitFailure = false,
    Map<String, String>? fieldErrors,
    String? publishedPropertyId,
  }) {
    return AddPropertyState(
      draftStatus: draftStatus ?? this.draftStatus,
      draft: draft ?? this.draft,
      draftFailure: resetDraftFailure
          ? null
          : draftFailure ?? this.draftFailure,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: resetSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      publishedPropertyId: publishedPropertyId ?? this.publishedPropertyId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    draftStatus,
    draft,
    draftFailure,
    submitStatus,
    submitFailure,
    fieldErrors,
    publishedPropertyId,
  ];
}
