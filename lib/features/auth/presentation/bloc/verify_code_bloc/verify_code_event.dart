part of 'verify_code_bloc.dart';

sealed class VerifyCodeEvent extends Equatable {
  const VerifyCodeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The first event, added when the BLoC is created. Starts the resend
/// countdown from [resendAfter].
final class VerifyCodeStarted extends VerifyCodeEvent {
  const VerifyCodeStarted({required this.phone, required this.resendAfter});

  /// E.164 number the code was sent to.
  final String phone;

  final Duration resendAfter;

  @override
  List<Object?> get props => <Object?>[phone, resendAfter];
}

/// The code input changed. Non-digits are dropped and the code is limited to
/// `Validators.otpLength` digits; the last digit submits automatically.
final class VerifyCodeChanged extends VerifyCodeEvent {
  const VerifyCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

final class VerifyCodeSubmitted extends VerifyCodeEvent {
  const VerifyCodeSubmitted();
}

final class VerifyCodeResendRequested extends VerifyCodeEvent {
  const VerifyCodeResendRequested();
}

/// Sent once per second by the BLoC's own countdown timer.
final class VerifyCodeTimerTicked extends VerifyCodeEvent {
  const VerifyCodeTimerTicked();
}
