part of 'calendar_conflict_bloc.dart';

sealed class CalendarConflictEvent extends Equatable {
  const CalendarConflictEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [conflictId]: added when the BLoC is created and on retry.
final class CalendarConflictRequested extends CalendarConflictEvent {
  const CalendarConflictRequested(this.conflictId);

  final String conflictId;

  @override
  List<Object?> get props => <Object?>[conflictId];
}

/// «Оставить Airbnb» / «Оставить ручную»: keeps [bookingId] and cancels the
/// other booking. Ignored while a resolve runs.
final class CalendarConflictBookingKept extends CalendarConflictEvent {
  const CalendarConflictBookingKept(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => <Object?>[bookingId];
}
