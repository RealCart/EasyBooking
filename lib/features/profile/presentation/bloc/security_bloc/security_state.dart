part of 'security_bloc.dart';

final class SecurityState extends Equatable {
  const SecurityState({
    this.loadStatus = RequestStatus.initial,
    this.overview,
    this.loadFailure,
    this.biometricStatus = RequestStatus.initial,
    this.biometricFailure,
    this.terminateStatus = RequestStatus.initial,
    this.terminateFailure,
  });

  final RequestStatus loadStatus;

  /// The loaded overview, replaced after every successful write.
  final SecurityOverviewEntity? overview;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The Face ID write; the switch is disabled while it is loading.
  final RequestStatus biometricStatus;

  /// Set when [biometricStatus] is [RequestStatus.failure].
  final Failure? biometricFailure;

  final RequestStatus terminateStatus;

  /// Set when [terminateStatus] is [RequestStatus.failure].
  final Failure? terminateFailure;

  SecurityState copyWith({
    RequestStatus? loadStatus,
    SecurityOverviewEntity? overview,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? biometricStatus,
    Failure? biometricFailure,
    bool resetBiometricFailure = false,
    RequestStatus? terminateStatus,
    Failure? terminateFailure,
    bool resetTerminateFailure = false,
  }) {
    return SecurityState(
      loadStatus: loadStatus ?? this.loadStatus,
      overview: overview ?? this.overview,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      biometricStatus: biometricStatus ?? this.biometricStatus,
      biometricFailure: resetBiometricFailure
          ? null
          : biometricFailure ?? this.biometricFailure,
      terminateStatus: terminateStatus ?? this.terminateStatus,
      terminateFailure: resetTerminateFailure
          ? null
          : terminateFailure ?? this.terminateFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    overview,
    loadFailure,
    biometricStatus,
    biometricFailure,
    terminateStatus,
    terminateFailure,
  ];
}
