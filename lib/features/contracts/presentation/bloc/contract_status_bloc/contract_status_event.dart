part of 'contract_status_bloc.dart';

sealed class ContractStatusEvent extends Equatable {
  const ContractStatusEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [contractId]: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class ContractStatusRequested extends ContractStatusEvent {
  const ContractStatusRequested(this.contractId);

  final String contractId;

  @override
  List<Object?> get props => <Object?>[contractId];
}

/// «Отправить повторно»: sends a new link to the contract's recipient.
final class ContractResendRequested extends ContractStatusEvent {
  const ContractResendRequested();
}
