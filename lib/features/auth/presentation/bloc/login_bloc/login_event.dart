part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The phone field changed. [phone] may be formatted; the state keeps only
/// the national digits.
final class LoginPhoneChanged extends LoginEvent {
  const LoginPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => <Object?>[phone];
}

/// The user asked for an SMS code.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}
