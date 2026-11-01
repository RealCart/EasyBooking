part of 'contract_guest_bloc.dart';

sealed class ContractGuestEvent extends Equatable {
  const ContractGuestEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [contractId]: added when the BLoC is created and on retry.
final class ContractGuestRequested extends ContractGuestEvent {
  const ContractGuestRequested(this.contractId);

  final String contractId;

  @override
  List<Object?> get props => <Object?>[contractId];
}

/// The user edited the form field [field] (a `ContractGuestFields` key).
final class ContractGuestFieldEdited extends ContractGuestEvent {
  const ContractGuestFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// «Перейти к условиям» with the validated form.
final class ContractGuestSubmitted extends ContractGuestEvent {
  const ContractGuestSubmitted(this.params);

  final UpdateContractGuestParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
