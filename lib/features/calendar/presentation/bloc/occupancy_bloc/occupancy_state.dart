part of 'occupancy_bloc.dart';

final class OccupancyState extends Equatable {
  const OccupancyState({
    this.loadStatus = RequestStatus.initial,
    this.weekStart,
    this.favoritesOnly = false,
    this.week,
    this.loadFailure,
  });

  final RequestStatus loadStatus;

  /// Monday of the week being shown or loaded; `null` until the first load,
  /// and while «Сегодня» loads the current week.
  final DateTime? weekStart;

  final bool favoritesOnly;

  /// The last loaded week. It may be another week than [weekStart] while a
  /// new one loads.
  final OccupancyWeekEntity? week;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The loaded week, when it is the selected one with the current scope.
  OccupancyWeekEntity? get selectedWeek {
    final OccupancyWeekEntity? week = this.week;
    if (week == null || !loadStatus.isSuccess || week.weekStart != weekStart) {
      return null;
    }
    return week;
  }

  OccupancyState copyWith({
    RequestStatus? loadStatus,
    DateTime? weekStart,
    bool resetWeekStart = false,
    bool? favoritesOnly,
    OccupancyWeekEntity? week,
    Failure? loadFailure,
    bool resetLoadFailure = false,
  }) {
    return OccupancyState(
      loadStatus: loadStatus ?? this.loadStatus,
      weekStart: resetWeekStart ? null : weekStart ?? this.weekStart,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      week: week ?? this.week,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    weekStart,
    favoritesOnly,
    week,
    loadFailure,
  ];
}
