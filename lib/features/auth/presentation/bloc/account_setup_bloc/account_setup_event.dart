part of 'account_setup_bloc.dart';

sealed class AccountSetupEvent extends Equatable {
  const AccountSetupEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The user edited the form field [field] (an `AccountFields` key).
final class AccountFieldEdited extends AccountSetupEvent {
  const AccountFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// The validated account form asked to create the account.
final class AccountSetupSubmitted extends AccountSetupEvent {
  const AccountSetupSubmitted(this.params);

  final CreateAccountParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// The user left account setup (back button); signs out.
final class AccountSetupCancelled extends AccountSetupEvent {
  const AccountSetupCancelled();
}
