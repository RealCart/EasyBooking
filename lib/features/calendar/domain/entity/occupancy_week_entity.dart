import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';

/// Which properties are taken during one week («Занятость»).
final class OccupancyWeekEntity extends Equatable {
  const OccupancyWeekEntity({
    required this.weekStart,
    required this.today,
    required this.rows,
    required this.syncCheckedAt,
    required this.isSyncHealthy,
  });

  /// Monday of the week, at midnight.
  final DateTime weekStart;

  /// The source's current day, at midnight, to highlight it.
  final DateTime today;

  /// One row per property, in the properties' order.
  final List<OccupancyRowEntity> rows;

  /// When the channel calendars were last checked.
  final DateTime syncCheckedAt;

  /// Every channel calendar imported without errors («Все каналы
  /// обновлены»).
  final bool isSyncHealthy;

  /// Monday to Sunday, at midnight.
  List<DateTime> get days {
    return List<DateTime>.unmodifiable(<DateTime>[
      for (int day = 0; day < DateTime.daysPerWeek; day++)
        weekStart.addDays(day),
    ]);
  }

  /// Midnight after Sunday: the exclusive end of the week.
  DateTime get weekEnd => weekStart.addDays(DateTime.daysPerWeek);

  bool get containsToday {
    return !today.isBefore(weekStart) && today.isBefore(weekEnd);
  }

  @override
  List<Object?> get props => <Object?>[
    weekStart,
    today,
    rows,
    syncCheckedAt,
    isSyncHealthy,
  ];
}
