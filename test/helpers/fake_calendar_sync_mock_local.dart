import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_schedule_entity.dart';

import 'fake_calendar_conflicts_repository.dart';
import 'fake_channels_repository.dart';

/// A stay of property [propertyId] for the schedule of the test week.
OccupancyBlockEntity testScheduleBlock({
  required String id,
  required String propertyId,
  required DateTime start,
  required DateTime end,
}) {
  return OccupancyBlockEntity(
    id: id,
    propertyId: propertyId,
    kind: OccupancyBlockKind.booking,
    start: start,
    end: end,
    bookingId: 'booking-$id',
    guestName: 'Гость $id',
    source: BookingSource.airbnb,
  );
}

/// The week of 19 October 2026: two stays of `p1`, one of `p2`, and one of
/// `p9`, which is not a known property.
OccupancyScheduleEntity testOccupancySchedule({bool isSyncHealthy = false}) {
  return OccupancyScheduleEntity(
    weekStart: DateTime(2026, 10, 19),
    today: DateTime(2026, 10, 22),
    blocks: <OccupancyBlockEntity>[
      testScheduleBlock(
        id: 's1',
        propertyId: 'p1',
        start: DateTime(2026, 10, 19, 14),
        end: DateTime(2026, 10, 21, 12),
      ),
      testScheduleBlock(
        id: 's2',
        propertyId: 'p2',
        start: DateTime(2026, 10, 20, 14),
        end: DateTime(2026, 10, 22, 12),
      ),
      testScheduleBlock(
        id: 's3',
        propertyId: 'p9',
        start: DateTime(2026, 10, 21, 14),
        end: DateTime(2026, 10, 23, 12),
      ),
      testScheduleBlock(
        id: 's4',
        propertyId: 'p1',
        start: DateTime(2026, 10, 23, 14),
        end: DateTime(2026, 10, 26, 12),
      ),
    ],
    syncCheckedAt: DateTime(2026, 10, 22, 9, 38),
    isSyncHealthy: isSyncHealthy,
  );
}

/// [CalendarSyncMockLocal] with settable results that records calls. Set
/// [error] to throw it from every call.
final class FakeCalendarSyncMockLocal implements CalendarSyncMockLocal {
  Either<Failure, OccupancyScheduleEntity> scheduleResult =
      Right<Failure, OccupancyScheduleEntity>(testOccupancySchedule());
  Either<Failure, ChannelsOverviewEntity> channelsResult =
      Right<Failure, ChannelsOverviewEntity>(testChannelsOverview());
  Either<Failure, ChannelEntity> syncResult = Right<Failure, ChannelEntity>(
    testAirbnbChannel(isRepaired: true),
  );
  Either<Failure, void> disconnectResult = const Right<Failure, void>(null);
  Either<Failure, CalendarConflictEntity> conflictResult =
      Right<Failure, CalendarConflictEntity>(testCalendarConflict());
  Either<Failure, CalendarConflictEntity> resolveResult =
      Right<Failure, CalendarConflictEntity>(
        testCalendarConflict(keptBookingId: conflictTestAirbnbBookingId),
      );
  Object? error;

  final List<DateTime?> scheduleRequests = <DateTime?>[];
  int channelsCount = 0;
  final List<String> syncRequests = <String>[];
  final List<String> disconnectRequests = <String>[];
  final List<String> conflictRequests = <String>[];
  final List<({String conflictId, String keepBookingId})> resolveRequests =
      <({String conflictId, String keepBookingId})>[];

  @override
  Future<Either<Failure, OccupancyScheduleEntity>> loadSchedule(
    DateTime? date,
  ) async {
    scheduleRequests.add(date);
    _throwIfSet();
    return scheduleResult;
  }

  @override
  Future<Either<Failure, ChannelsOverviewEntity>> loadChannels() async {
    channelsCount += 1;
    _throwIfSet();
    return channelsResult;
  }

  @override
  Future<Either<Failure, ChannelEntity>> syncChannel(String id) async {
    syncRequests.add(id);
    _throwIfSet();
    return syncResult;
  }

  @override
  Future<Either<Failure, void>> disconnectChannel(String id) async {
    disconnectRequests.add(id);
    _throwIfSet();
    return disconnectResult;
  }

  @override
  Future<Either<Failure, CalendarConflictEntity>> loadConflict(
    String id,
  ) async {
    conflictRequests.add(id);
    _throwIfSet();
    return conflictResult;
  }

  @override
  Future<Either<Failure, CalendarConflictEntity>> resolveConflict({
    required String conflictId,
    required String keepBookingId,
  }) async {
    resolveRequests.add((
      conflictId: conflictId,
      keepBookingId: keepBookingId,
    ));
    _throwIfSet();
    return resolveResult;
  }

  void _throwIfSet() {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
