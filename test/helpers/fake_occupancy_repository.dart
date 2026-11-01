import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/occupancy_repository.dart';

/// Thursday, 22 October 2026, as in the design.
final DateTime occupancyTestToday = DateTime(2026, 10, 22);

/// Monday of [occupancyTestToday]'s week.
final DateTime occupancyTestWeekStart = DateTime(2026, 10, 19);

/// The rows of the test week: Esentai `p1` with a conflicting Airbnb stay
/// and a direct stay, Mega Towers `p2` with a Booking.com stay, and Samal
/// `p3` closed for repairs.
List<OccupancyRowEntity> testOccupancyRows() {
  return <OccupancyRowEntity>[
    OccupancyRowEntity(
      propertyId: 'p1',
      propertyName: 'Esentai City',
      unit: '84',
      pricePerNight: 42500,
      blocks: <OccupancyBlockEntity>[
        OccupancyBlockEntity(
          id: 'stay-b1',
          propertyId: 'p1',
          kind: OccupancyBlockKind.booking,
          start: DateTime(2026, 10, 19, 14),
          end: DateTime(2026, 10, 21, 12),
          bookingId: 'b1',
          guestName: 'Айжан',
          source: BookingSource.airbnb,
          conflictId: 'c1',
        ),
        OccupancyBlockEntity(
          id: 'stay-b2',
          propertyId: 'p1',
          kind: OccupancyBlockKind.booking,
          start: DateTime(2026, 10, 23, 14),
          end: DateTime(2026, 10, 25, 12),
          bookingId: 'b2',
          guestName: 'Марат',
          source: BookingSource.direct,
        ),
      ],
    ),
    OccupancyRowEntity(
      propertyId: 'p2',
      propertyName: 'Mega Towers',
      unit: '126',
      pricePerNight: 32000,
      blocks: <OccupancyBlockEntity>[
        OccupancyBlockEntity(
          id: 'stay-b3',
          propertyId: 'p2',
          kind: OccupancyBlockKind.booking,
          start: DateTime(2026, 10, 20, 14),
          end: DateTime(2026, 10, 23, 12),
          bookingId: 'b3',
          guestName: 'Данияр',
          source: BookingSource.bookingCom,
        ),
      ],
    ),
    OccupancyRowEntity(
      propertyId: 'p3',
      propertyName: 'Samal Residence',
      unit: '12',
      pricePerNight: 38000,
      blocks: <OccupancyBlockEntity>[
        OccupancyBlockEntity(
          id: 'maintenance-p3',
          propertyId: 'p3',
          kind: OccupancyBlockKind.maintenance,
          start: DateTime(2026, 10, 22),
          end: DateTime(2026, 10, 24),
        ),
      ],
    ),
  ];
}

/// The week starting [weekStart] with [rows] (by default
/// [testOccupancyRows] for the current week, none for any other week).
OccupancyWeekEntity testOccupancyWeek(
  DateTime weekStart, {
  List<OccupancyRowEntity>? rows,
  bool isSyncHealthy = true,
}) {
  return OccupancyWeekEntity(
    weekStart: weekStart,
    today: occupancyTestToday,
    rows:
        rows ??
        (weekStart == occupancyTestWeekStart
            ? testOccupancyRows()
            : const <OccupancyRowEntity>[]),
    syncCheckedAt: DateTime(2026, 10, 22, 9, 38),
    isSyncHealthy: isSyncHealthy,
  );
}

/// [OccupancyRepository] that records requests and answers with
/// [testOccupancyWeek] for the requested week, or with [weekFailure].
///
/// Set [holdWeeks] to keep the next requests pending; each gets a completer
/// in [heldWeeks]. Set [error] to throw it from every request.
final class FakeOccupancyRepository implements OccupancyRepository {
  Failure? weekFailure;
  Object? error;
  bool isSyncHealthy = true;

  /// Rows of every week answered, instead of the default ones.
  List<OccupancyRowEntity>? rows;

  bool holdWeeks = false;
  final List<Completer<Either<Failure, OccupancyWeekEntity>>> heldWeeks =
      <Completer<Either<Failure, OccupancyWeekEntity>>>[];

  final List<({DateTime? date, bool favoritesOnly})> requests =
      <({DateTime? date, bool favoritesOnly})>[];

  @override
  Future<Either<Failure, OccupancyWeekEntity>> getWeek({
    required bool favoritesOnly,
    DateTime? date,
  }) async {
    requests.add((date: date, favoritesOnly: favoritesOnly));
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
    if (holdWeeks) {
      final Completer<Either<Failure, OccupancyWeekEntity>> completer =
          Completer<Either<Failure, OccupancyWeekEntity>>();
      heldWeeks.add(completer);
      return completer.future;
    }
    final Failure? failure = weekFailure;
    if (failure != null) {
      return Left<Failure, OccupancyWeekEntity>(failure);
    }
    return Right<Failure, OccupancyWeekEntity>(
      testOccupancyWeek(
        (date ?? occupancyTestToday).startOfWeek,
        rows: rows,
        isSyncHealthy: isSyncHealthy,
      ),
    );
  }
}
