part of 'billing_bloc.dart';

final class BillingState extends Equatable {
  const BillingState({
    this.loadStatus = RequestStatus.initial,
    this.overview,
    this.loadFailure,
    this.changePlanStatus = RequestStatus.initial,
    this.changePlanFailure,
  });

  final RequestStatus loadStatus;

  /// The loaded overview, replaced after a plan change.
  final BillingOverviewEntity? overview;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus changePlanStatus;

  /// Set when [changePlanStatus] is [RequestStatus.failure]; a
  /// `ValidationFailure` with `ProfileErrorCodes.planLimitExceeded` means
  /// the workspace exceeds the chosen plan's limits.
  final Failure? changePlanFailure;

  BillingState copyWith({
    RequestStatus? loadStatus,
    BillingOverviewEntity? overview,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? changePlanStatus,
    Failure? changePlanFailure,
    bool resetChangePlanFailure = false,
  }) {
    return BillingState(
      loadStatus: loadStatus ?? this.loadStatus,
      overview: overview ?? this.overview,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      changePlanStatus: changePlanStatus ?? this.changePlanStatus,
      changePlanFailure: resetChangePlanFailure
          ? null
          : changePlanFailure ?? this.changePlanFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    overview,
    loadFailure,
    changePlanStatus,
    changePlanFailure,
  ];
}
