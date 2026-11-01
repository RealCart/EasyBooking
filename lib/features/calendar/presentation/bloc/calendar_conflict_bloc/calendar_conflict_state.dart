part of 'calendar_conflict_bloc.dart';

final class CalendarConflictState extends Equatable {
  const CalendarConflictState({
    this.conflictId = '',
    this.loadStatus = RequestStatus.initial,
    this.conflict,
    this.loadFailure,
    this.resolveStatus = RequestStatus.initial,
    this.keepingBookingId,
    this.resolveFailure,
  });

  /// The requested conflict, for retrying a failed load.
  final String conflictId;

  final RequestStatus loadStatus;

  /// After a successful resolve, the resolved conflict.
  final CalendarConflictEntity? conflict;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// [RequestStatus.success] means the conflict was just resolved.
  final RequestStatus resolveStatus;

  /// The booking being kept while [resolveStatus] is loading, to show the
  /// progress on its button.
  final String? keepingBookingId;

  /// The failure of the last resolve, for a one-off message.
  final Failure? resolveFailure;

  CalendarConflictState copyWith({
    String? conflictId,
    RequestStatus? loadStatus,
    CalendarConflictEntity? conflict,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? resolveStatus,
    String? keepingBookingId,
    bool resetKeepingBookingId = false,
    Failure? resolveFailure,
    bool resetResolveFailure = false,
  }) {
    return CalendarConflictState(
      conflictId: conflictId ?? this.conflictId,
      loadStatus: loadStatus ?? this.loadStatus,
      conflict: conflict ?? this.conflict,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      resolveStatus: resolveStatus ?? this.resolveStatus,
      keepingBookingId: resetKeepingBookingId
          ? null
          : keepingBookingId ?? this.keepingBookingId,
      resolveFailure: resetResolveFailure
          ? null
          : resolveFailure ?? this.resolveFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    conflictId,
    loadStatus,
    conflict,
    loadFailure,
    resolveStatus,
    keepingBookingId,
    resolveFailure,
  ];
}
