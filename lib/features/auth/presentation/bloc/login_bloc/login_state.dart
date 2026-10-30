part of 'login_bloc.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.phone = '',
    this.status = RequestStatus.initial,
    this.failure,
    this.challenge,
  });

  /// National digits typed so far (at most ten), without `+7`.
  final String phone;

  /// Status of the send-code request.
  final RequestStatus status;

  /// Set when [status] is [RequestStatus.failure].
  final Failure? failure;

  /// Set when [status] is [RequestStatus.success].
  final OtpChallengeEntity? challenge;

  bool get canSubmit => Validators.isValidPhone(phone) && !status.isLoading;

  LoginState copyWith({
    String? phone,
    RequestStatus? status,
    Failure? failure,
    bool resetFailure = false,
    OtpChallengeEntity? challenge,
    bool resetChallenge = false,
  }) {
    return LoginState(
      phone: phone ?? this.phone,
      status: status ?? this.status,
      failure: resetFailure ? null : failure ?? this.failure,
      challenge: resetChallenge ? null : challenge ?? this.challenge,
    );
  }

  @override
  List<Object?> get props => <Object?>[phone, status, failure, challenge];
}
