part of 'verify_code_bloc.dart';

final class VerifyCodeState extends Equatable {
  const VerifyCodeState({
    this.phone = '',
    this.verifyStatus = RequestStatus.initial,
    this.verifyFailure,
    this.resendStatus = RequestStatus.initial,
    this.resendFailure,
    this.resendAvailableIn = Duration.zero,
  });

  /// E.164 number the code was sent to.
  final String phone;

  final RequestStatus verifyStatus;

  /// Set when [verifyStatus] is [RequestStatus.failure].
  final Failure? verifyFailure;

  final RequestStatus resendStatus;

  /// Set when [resendStatus] is [RequestStatus.failure].
  final Failure? resendFailure;

  /// Time left before a new code may be requested; [Duration.zero] means
  /// resend is allowed.
  final Duration resendAvailableIn;

  bool get canResend =>
      resendAvailableIn <= Duration.zero &&
      !resendStatus.isLoading &&
      !verifyStatus.isLoading;

  /// Whether a code may be submitted now; the screen also requires a
  /// complete code.
  bool get canSubmit =>
      !verifyStatus.isLoading &&
      !verifyStatus.isSuccess &&
      !resendStatus.isLoading;

  VerifyCodeState copyWith({
    String? phone,
    RequestStatus? verifyStatus,
    Failure? verifyFailure,
    bool resetVerifyFailure = false,
    RequestStatus? resendStatus,
    Failure? resendFailure,
    bool resetResendFailure = false,
    Duration? resendAvailableIn,
  }) {
    return VerifyCodeState(
      phone: phone ?? this.phone,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      verifyFailure: resetVerifyFailure
          ? null
          : verifyFailure ?? this.verifyFailure,
      resendStatus: resendStatus ?? this.resendStatus,
      resendFailure: resetResendFailure
          ? null
          : resendFailure ?? this.resendFailure,
      resendAvailableIn: resendAvailableIn ?? this.resendAvailableIn,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    phone,
    verifyStatus,
    verifyFailure,
    resendStatus,
    resendFailure,
    resendAvailableIn,
  ];
}
