import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';

/// The events of one [date], and the state of the channel sync.
final class CalendarDayEntity extends Equatable {
  const CalendarDayEntity({
    required this.date,
    required this.today,
    required this.events,
    required this.syncCheckedAt,
    required this.isSyncHealthy,
  });

  /// The day shown, at midnight.
  final DateTime date;

  /// The source's current day, at midnight, for relative labels.
  final DateTime today;

  /// Ordered by time.
  final List<CalendarEventEntity> events;

  final DateTime syncCheckedAt;

  /// Every channel calendar imported without errors.
  final bool isSyncHealthy;

  CalendarDayEntity withEvents(List<CalendarEventEntity> events) {
    return CalendarDayEntity(
      date: date,
      today: today,
      events: events,
      syncCheckedAt: syncCheckedAt,
      isSyncHealthy: isSyncHealthy,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    date,
    today,
    events,
    syncCheckedAt,
    isSyncHealthy,
  ];
}
