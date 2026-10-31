part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The validated login form asked for an SMS code.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted(this.params);

  final SendCodeParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
