part of 'contract_guest_bloc.dart';

final class ContractGuestState extends Equatable {
  const ContractGuestState({
    this.contractId = '',
    this.loadStatus = RequestStatus.initial,
    this.contract,
    this.loadFailure,
    this.submitStatus = RequestStatus.initial,
    this.submitFailure,
    this.fieldErrors = const <String, String>{},
  });

  /// The requested contract id from the route, for retrying a failed load.
  final String contractId;

  final RequestStatus loadStatus;

  /// The last loaded contract; kept while reloading or after a failed
  /// reload, and replaced by the saved one after a successful submit.
  final ContractEntity? contract;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// Status of saving the guest data.
  final RequestStatus submitStatus;

  /// A submit failure that does not belong to a single field, for example
  /// `ValidationFailure(code: ContractErrorCodes.alreadySigned)`.
  final Failure? submitFailure;

  /// `ContractGuestFields` key to a `ContractErrorCodes` field code.
  final Map<String, String> fieldErrors;

  ContractGuestState copyWith({
    String? contractId,
    RequestStatus? loadStatus,
    ContractEntity? contract,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? submitStatus,
    Failure? submitFailure,
    bool resetSubmitFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return ContractGuestState(
      contractId: contractId ?? this.contractId,
      loadStatus: loadStatus ?? this.loadStatus,
      contract: contract ?? this.contract,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: resetSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    contractId,
    loadStatus,
    contract,
    loadFailure,
    submitStatus,
    submitFailure,
    fieldErrors,
  ];
}
