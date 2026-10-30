part of 'account_setup_bloc.dart';

sealed class AccountSetupEvent extends Equatable {
  const AccountSetupEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AccountFirstNameChanged extends AccountSetupEvent {
  const AccountFirstNameChanged(this.firstName);

  final String firstName;

  @override
  List<Object?> get props => <Object?>[firstName];
}

final class AccountLastNameChanged extends AccountSetupEvent {
  const AccountLastNameChanged(this.lastName);

  final String lastName;

  @override
  List<Object?> get props => <Object?>[lastName];
}

final class AccountEmailChanged extends AccountSetupEvent {
  const AccountEmailChanged(this.email);

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}

final class AccountTeamNameChanged extends AccountSetupEvent {
  const AccountTeamNameChanged(this.teamName);

  final String teamName;

  @override
  List<Object?> get props => <Object?>[teamName];
}

final class AccountCitySelected extends AccountSetupEvent {
  const AccountCitySelected(this.city);

  final CityEntity city;

  @override
  List<Object?> get props => <Object?>[city];
}

final class AccountSetupSubmitted extends AccountSetupEvent {
  const AccountSetupSubmitted();
}

/// The user left account setup (back button); signs out.
final class AccountSetupCancelled extends AccountSetupEvent {
  const AccountSetupCancelled();
}
