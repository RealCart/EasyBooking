part of 'verify_code_bloc.dart';

final class VerifyCodeState extends Equatable {
  const VerifyCodeState({
    this.phone = '',
    this.code = '',
    this.verifyStatus = RequestStatus.initial,
    this.verifyFailure,
    this.resendStatus = RequestStatus.initial,
    this.resendFailure,
    this.resendAvailableIn = Duration.zero,
  });

  /// E.164 number the code was sent to.
  final String phone;

  /// Digits entered so far, at most `Validators.otpLength`.
  final String code;

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

  /// Whether the confirm button is enabled.
  bool get canSubmit =>
      code.length == Validators.otpLength &&
      !verifyStatus.isLoading &&
      !verifyStatus.isSuccess &&
      !resendStatus.isLoading;

  VerifyCodeState copyWith({
    String? phone,
    String? code,
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
      code: code ?? this.code,
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
    code,
    verifyStatus,
    verifyFailure,
    resendStatus,
    resendFailure,
    resendAvailableIn,
  ];
}
