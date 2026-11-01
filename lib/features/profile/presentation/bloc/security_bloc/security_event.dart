part of 'security_bloc.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the overview: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class SecurityRequested extends SecurityEvent {
  const SecurityRequested();
}

/// The user switched «Вход по Face ID» to [isEnabled].
final class SecurityBiometricLoginToggled extends SecurityEvent {
  const SecurityBiometricLoginToggled({required this.isEnabled});

  final bool isEnabled;

  @override
  List<Object?> get props => <Object?>[isEnabled];
}

/// The user confirmed «Завершить другие сеансы».
final class SecurityOtherSessionsTerminateRequested extends SecurityEvent {
  const SecurityOtherSessionsTerminateRequested();
}
