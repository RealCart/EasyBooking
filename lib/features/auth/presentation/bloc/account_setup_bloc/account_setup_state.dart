part of 'account_setup_bloc.dart';

final class AccountSetupState extends Equatable {
  const AccountSetupState({
    this.status = RequestStatus.initial,
    this.failure,
    this.fieldErrors = const <String, String>{},
  });

  /// Status of the create-account request (and of signing out on cancel).
  final RequestStatus status;

  /// A failure that does not belong to a single field.
  final Failure? failure;

  /// `AccountFields` key to an `AuthErrorCodes` field code or a server text.
  final Map<String, String> fieldErrors;

  AccountSetupState copyWith({
    RequestStatus? status,
    Failure? failure,
    bool resetFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return AccountSetupState(
      status: status ?? this.status,
      failure: resetFailure ? null : failure ?? this.failure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, failure, fieldErrors];
}
