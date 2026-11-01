part of 'guest_detail_bloc.dart';

final class GuestDetailState extends Equatable {
  const GuestDetailState({
    this.guestId = '',
    this.loadStatus = RequestStatus.initial,
    this.guest,
    this.loadFailure,
    this.createContractStatus = RequestStatus.initial,
    this.createdContractId,
    this.createContractFailure,
  });

  /// The requested guest, for retrying a failed load.
  final String guestId;

  final RequestStatus loadStatus;

  /// Kept while a retry runs.
  final GuestEntity? guest;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The «Создать договор» request, independent of [loadStatus].
  final RequestStatus createContractStatus;

  /// The draft to open with `AppRoutes.contract`; set when
  /// [createContractStatus] becomes [RequestStatus.success], cleared when
  /// the next creation starts.
  final String? createdContractId;

  /// Set when [createContractStatus] is [RequestStatus.failure], for a
  /// one-off message.
  final Failure? createContractFailure;

  GuestDetailState copyWith({
    String? guestId,
    RequestStatus? loadStatus,
    GuestEntity? guest,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? createContractStatus,
    String? createdContractId,
    bool resetCreatedContractId = false,
    Failure? createContractFailure,
    bool resetCreateContractFailure = false,
  }) {
    return GuestDetailState(
      guestId: guestId ?? this.guestId,
      loadStatus: loadStatus ?? this.loadStatus,
      guest: guest ?? this.guest,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      createContractStatus: createContractStatus ?? this.createContractStatus,
      createdContractId: resetCreatedContractId
          ? null
          : createdContractId ?? this.createdContractId,
      createContractFailure: resetCreateContractFailure
          ? null
          : createContractFailure ?? this.createContractFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    guestId,
    loadStatus,
    guest,
    loadFailure,
    createContractStatus,
    createdContractId,
    createContractFailure,
  ];
}
