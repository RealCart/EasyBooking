part of 'contract_send_bloc.dart';

final class ContractSendState extends Equatable {
  const ContractSendState({
    this.contractId = '',
    this.loadStatus = RequestStatus.initial,
    this.contract,
    this.loadFailure,
    this.sendStatus = RequestStatus.initial,
    this.sendFailure,
  });

  /// The requested contract id from the route, for retrying a failed load.
  final String contractId;

  final RequestStatus loadStatus;

  /// The last loaded contract; kept while reloading or after a failed
  /// reload, and replaced by the sent one after a successful send.
  final ContractEntity? contract;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus sendStatus;

  /// Set when [sendStatus] is [RequestStatus.failure]: a `ValidationFailure`
  /// with `ContractErrorCodes.invalidPhone`, `invalidEmail`, or
  /// `alreadySigned`, or any other failure.
  final Failure? sendFailure;

  ContractSendState copyWith({
    String? contractId,
    RequestStatus? loadStatus,
    ContractEntity? contract,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? sendStatus,
    Failure? sendFailure,
    bool resetSendFailure = false,
  }) {
    return ContractSendState(
      contractId: contractId ?? this.contractId,
      loadStatus: loadStatus ?? this.loadStatus,
      contract: contract ?? this.contract,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      sendStatus: sendStatus ?? this.sendStatus,
      sendFailure: resetSendFailure ? null : sendFailure ?? this.sendFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    contractId,
    loadStatus,
    contract,
    loadFailure,
    sendStatus,
    sendFailure,
  ];
}
