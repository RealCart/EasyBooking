part of 'account_setup_bloc.dart';

final class AccountSetupState extends Equatable {
  const AccountSetupState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.teamName = '',
    this.city,
    this.status = RequestStatus.initial,
    this.failure,
    this.fieldErrors = const <String, String>{},
  });

  final String firstName;
  final String lastName;
  final String email;
  final String teamName;
  final CityEntity? city;

  /// Status of the create-account request (and of signing out on cancel).
  final RequestStatus status;

  /// A failure that does not belong to a single field.
  final Failure? failure;

  /// `AccountFields` key to an `AuthErrorCodes` field code or a server text.
  final Map<String, String> fieldErrors;

  AccountSetupState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? teamName,
    CityEntity? city,
    bool resetCity = false,
    RequestStatus? status,
    Failure? failure,
    bool resetFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return AccountSetupState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      teamName: teamName ?? this.teamName,
      city: resetCity ? null : city ?? this.city,
      status: status ?? this.status,
      failure: resetFailure ? null : failure ?? this.failure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    email,
    teamName,
    city,
    status,
    failure,
    fieldErrors,
  ];
}
