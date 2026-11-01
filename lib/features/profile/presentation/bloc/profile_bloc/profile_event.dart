part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the profile: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

/// The user confirmed «Выйти из аккаунта».
final class ProfileSignOutRequested extends ProfileEvent {
  const ProfileSignOutRequested();
}
