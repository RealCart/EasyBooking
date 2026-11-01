part of 'occupancy_bloc.dart';

sealed class OccupancyEvent extends Equatable {
  const OccupancyEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the selected week (the current one at first): added when the BLoC
/// is created, on retry, and on pull-to-refresh.
final class OccupancyRequested extends OccupancyEvent {
  const OccupancyRequested();
}

/// Shows the week containing [date], for example the next or previous one.
final class OccupancyWeekSelected extends OccupancyEvent {
  const OccupancyWeekSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => <Object?>[date];
}

/// «Сегодня»: back to the source's current week.
final class OccupancyCurrentWeekSelected extends OccupancyEvent {
  const OccupancyCurrentWeekSelected();
}

/// «Все объекты» or «Избранные».
final class OccupancyScopeSelected extends OccupancyEvent {
  const OccupancyScopeSelected({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  List<Object?> get props => <Object?>[favoritesOnly];
}
