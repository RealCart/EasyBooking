part of 'contract_send_bloc.dart';

sealed class ContractSendEvent extends Equatable {
  const ContractSendEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [contractId]: added when the BLoC is created and on retry.
final class ContractSendRequested extends ContractSendEvent {
  const ContractSendRequested(this.contractId);

  final String contractId;

  @override
  List<Object?> get props => <Object?>[contractId];
}

/// «Отправить на подпись» with the chosen channel and address.
final class ContractSendSubmitted extends ContractSendEvent {
  const ContractSendSubmitted(this.params);

  final SendContractParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
