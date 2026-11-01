import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_conflicts_repository.dart';

/// The Airbnb booking `b1` of [testCalendarConflict], listed first.
const String conflictTestAirbnbBookingId = 'b1';

/// The direct booking `b2` of [testCalendarConflict], listed second.
const String conflictTestDirectBookingId = 'b2';

/// When the source answered: 22 October 2026, 10:00.
final DateTime conflictTestReceivedAt = DateTime(2026, 10, 22, 10);

/// Conflict `c1` of Esentai City · 84 on 24–25 October: a confirmed Airbnb
/// stay of Айжан against a direct stay of Марат, created on 21 October,
/// the day before [conflictTestReceivedAt]. Both are confirmed unless
/// [isDirectConfirmed] is `false`.
CalendarConflictEntity testCalendarConflict({
  String? keptBookingId,
  bool isDirectConfirmed = true,
}) {
  return CalendarConflictEntity(
    id: 'c1',
    propertyId: 'p1',
    propertyName: 'Esentai City',
    unit: '84',
    overlapStart: DateTime(2026, 10, 24),
    overlapEnd: DateTime(2026, 10, 25),
    bookings: <ConflictBookingEntity>[
      ConflictBookingEntity(
        bookingId: conflictTestAirbnbBookingId,
        source: BookingSource.airbnb,
        guestName: 'Айжан',
        checkIn: DateTime(2026, 10, 22, 14),
        checkOut: DateTime(2026, 10, 25, 12),
        totalPrice: 127500,
        createdAt: DateTime(2026, 10, 16, 11, 24),
        isConfirmed: true,
        isPhoneVerified: false,
        confirmationCode: 'HM73P2',
      ),
      ConflictBookingEntity(
        bookingId: conflictTestDirectBookingId,
        source: BookingSource.direct,
        guestName: 'Марат',
        checkIn: DateTime(2026, 10, 24, 14),
        checkOut: DateTime(2026, 10, 27, 12),
        totalPrice: 114000,
        createdAt: DateTime(2026, 10, 21, 19, 20),
        isConfirmed: isDirectConfirmed,
        isPhoneVerified: true,
      ),
    ],
    position: 1,
    total: 1,
    receivedAt: conflictTestReceivedAt,
    keptBookingId: keptBookingId,
  );
}

/// [CalendarConflictsRepository] over [testCalendarConflict] that records
/// calls. By default a resolve keeps the requested booking.
///
/// Set a `hold…` flag to keep the next calls pending; each gets a completer
/// in the matching `held…` list. Set [error] to throw it from every call.
final class FakeCalendarConflictsRepository
    implements CalendarConflictsRepository {
  Either<Failure, CalendarConflictEntity> conflictResult =
      Right<Failure, CalendarConflictEntity>(testCalendarConflict());

  /// `null` answers with the conflict resolved for the kept booking.
  Either<Failure, CalendarConflictEntity>? resolveResult;
  Object? error;

  bool holdConflict = false;
  final List<Completer<Either<Failure, CalendarConflictEntity>>> heldConflicts =
      <Completer<Either<Failure, CalendarConflictEntity>>>[];
  bool holdResolve = false;
  final List<Completer<Either<Failure, CalendarConflictEntity>>> heldResolves =
      <Completer<Either<Failure, CalendarConflictEntity>>>[];

  final List<String> conflictRequests = <String>[];
  final List<({String conflictId, String keepBookingId})> resolveRequests =
      <({String conflictId, String keepBookingId})>[];

  @override
  Future<Either<Failure, CalendarConflictEntity>> getConflict(String id) async {
    conflictRequests.add(id);
    _throwIfSet();
    if (holdConflict) {
      final Completer<Either<Failure, CalendarConflictEntity>> completer =
          Completer<Either<Failure, CalendarConflictEntity>>();
      heldConflicts.add(completer);
      return completer.future;
    }
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
    if (holdResolve) {
      final Completer<Either<Failure, CalendarConflictEntity>> completer =
          Completer<Either<Failure, CalendarConflictEntity>>();
      heldResolves.add(completer);
      return completer.future;
    }
    return resolveResult ??
        Right<Failure, CalendarConflictEntity>(
          testCalendarConflict(keptBookingId: keepBookingId),
        );
  }

  void _throwIfSet() {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
