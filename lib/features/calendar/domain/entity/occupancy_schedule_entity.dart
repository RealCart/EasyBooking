import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';

/// The blocks of every property in one week, before they are grouped into
/// property rows.
final class OccupancyScheduleEntity extends Equatable {
  const OccupancyScheduleEntity({
    required this.weekStart,
    required this.today,
    required this.blocks,
    required this.syncCheckedAt,
    required this.isSyncHealthy,
  });

  /// Monday of the week, at midnight.
  final DateTime weekStart;

  /// The source's current day, at midnight.
  final DateTime today;

  /// Blocks that overlap the week, ordered by start.
  final List<OccupancyBlockEntity> blocks;

  /// When the channel calendars were last checked.
  final DateTime syncCheckedAt;

  /// Every channel calendar imported without errors.
  final bool isSyncHealthy;

  @override
  List<Object?> get props => <Object?>[
    weekStart,
    today,
    blocks,
    syncCheckedAt,
    isSyncHealthy,
  ];
}
