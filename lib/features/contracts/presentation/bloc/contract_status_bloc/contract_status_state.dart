part of 'contract_status_bloc.dart';

final class ContractStatusState extends Equatable {
  const ContractStatusState({
    this.contractId = '',
    this.loadStatus = RequestStatus.initial,
    this.contract,
    this.loadFailure,
    this.resendStatus = RequestStatus.initial,
    this.resendFailure,
  });

  /// The requested contract id from the route, for retrying a failed load.
  final String contractId;

  final RequestStatus loadStatus;

  /// The last loaded contract; kept while reloading or after a failed
  /// reload, and replaced by the sent one after a successful resend.
  final ContractEntity? contract;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus resendStatus;

  /// The failure of the last resend, for a one-off message. Cleared when the
  /// next resend starts.
  final Failure? resendFailure;

  /// Whether «Отправить повторно» can be pressed.
  bool get canResend {
    final ContractEntity? contract = this.contract;
    return contract != null &&
        contract.status.canSend &&
        !resendStatus.isLoading;
  }

  ContractStatusState copyWith({
    String? contractId,
    RequestStatus? loadStatus,
    ContractEntity? contract,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? resendStatus,
    Failure? resendFailure,
    bool resetResendFailure = false,
  }) {
    return ContractStatusState(
      contractId: contractId ?? this.contractId,
      loadStatus: loadStatus ?? this.loadStatus,
      contract: contract ?? this.contract,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      resendStatus: resendStatus ?? this.resendStatus,
      resendFailure: resetResendFailure
          ? null
          : resendFailure ?? this.resendFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    contractId,
    loadStatus,
    contract,
    loadFailure,
    resendStatus,
    resendFailure,
  ];
}
