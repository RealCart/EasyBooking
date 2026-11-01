part of 'edit_profile_bloc.dart';

final class EditProfileState extends Equatable {
  const EditProfileState({
    this.loadStatus = RequestStatus.initial,
    this.details,
    this.loadFailure,
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
    this.fieldErrors = const <String, String>{},
  });

  final RequestStatus loadStatus;

  /// The loaded details, replaced by the saved ones after a save. The form
  /// fills its controllers from them once; the BLoC holds no field values.
  final ProfileDetailsEntity? details;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// [RequestStatus.success] means saved: leave the screen.
  final RequestStatus saveStatus;

  /// A save failure that does not belong to a single field.
  final Failure? saveFailure;

  /// `ProfileFields` key to a `FieldErrorCodes` field code.
  final Map<String, String> fieldErrors;

  EditProfileState copyWith({
    RequestStatus? loadStatus,
    ProfileDetailsEntity? details,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool resetSaveFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return EditProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      details: details ?? this.details,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: resetSaveFailure ? null : saveFailure ?? this.saveFailure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    details,
    loadFailure,
    saveStatus,
    saveFailure,
    fieldErrors,
  ];
}
