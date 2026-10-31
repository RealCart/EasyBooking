part of 'login_bloc.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.status = RequestStatus.initial,
    this.failure,
    this.challenge,
  });

  /// Status of the send-code request.
  final RequestStatus status;

  /// Set when [status] is [RequestStatus.failure].
  final Failure? failure;

  /// Set when [status] is [RequestStatus.success].
  final OtpChallengeEntity? challenge;

  LoginState copyWith({
    RequestStatus? status,
    Failure? failure,
    bool resetFailure = false,
    OtpChallengeEntity? challenge,
    bool resetChallenge = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      failure: resetFailure ? null : failure ?? this.failure,
      challenge: resetChallenge ? null : challenge ?? this.challenge,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, failure, challenge];
}
