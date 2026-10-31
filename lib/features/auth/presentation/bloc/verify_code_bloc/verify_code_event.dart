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

/// The user typed in the code field. Clears the error of a failed check.
final class VerifyCodeEdited extends VerifyCodeEvent {
  const VerifyCodeEdited();
}

/// The validated code form asked to check [params].
final class VerifyCodeSubmitted extends VerifyCodeEvent {
  const VerifyCodeSubmitted(this.params);

  final VerifyCodeParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

final class VerifyCodeResendRequested extends VerifyCodeEvent {
  const VerifyCodeResendRequested();
}

/// Sent once per second by the BLoC's own countdown timer.
final class VerifyCodeTimerTicked extends VerifyCodeEvent {
  const VerifyCodeTimerTicked();
}
