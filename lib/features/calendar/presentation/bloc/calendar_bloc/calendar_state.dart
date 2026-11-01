part of 'calendar_bloc.dart';

final class CalendarState extends Equatable {
  const CalendarState({
    this.loadStatus = RequestStatus.initial,
    this.selectedDate,
    this.favoritesOnly = false,
    this.day,
    this.loadFailure,
  });

  final RequestStatus loadStatus;

  /// The day being shown or loaded, at midnight; `null` until the first
  /// load tells which day is today.
  final DateTime? selectedDate;

  final bool favoritesOnly;

  /// The last loaded day. It may be another day than [selectedDate] while
  /// a new one loads.
  final CalendarDayEntity? day;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The loaded day, when it is the selected one with the current scope.
  CalendarDayEntity? get selectedDay {
    final CalendarDayEntity? day = this.day;
    if (day == null || !loadStatus.isSuccess || day.date != selectedDate) {
      return null;
    }
    return day;
  }

  CalendarState copyWith({
    RequestStatus? loadStatus,
    DateTime? selectedDate,
    bool? favoritesOnly,
    CalendarDayEntity? day,
    Failure? loadFailure,
    bool resetLoadFailure = false,
  }) {
    return CalendarState(
      loadStatus: loadStatus ?? this.loadStatus,
      selectedDate: selectedDate ?? this.selectedDate,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      day: day ?? this.day,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    selectedDate,
    favoritesOnly,
    day,
    loadFailure,
  ];
}
