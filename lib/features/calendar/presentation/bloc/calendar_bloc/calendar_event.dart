part of 'calendar_bloc.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the selected day (today at first): added when the BLoC is created,
/// on retry, and on pull-to-refresh.
final class CalendarRequested extends CalendarEvent {
  const CalendarRequested();
}

final class CalendarDaySelected extends CalendarEvent {
  const CalendarDaySelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => <Object?>[date];
}

/// «Все объекты» or «Избранные».
final class CalendarScopeSelected extends CalendarEvent {
  const CalendarScopeSelected({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  List<Object?> get props => <Object?>[favoritesOnly];
}
