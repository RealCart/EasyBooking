import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';

/// Served by a mock source until the calendar API exists.
abstract interface class CalendarConflictsRepository {
  /// The conflict [id], resolved or not; an unknown id is a failure.
  Future<Either<Failure, CalendarConflictEntity>> getConflict(String id);

  /// Keeps [keepBookingId] and cancels the other booking in EasyBooking.
  /// Returns the resolved conflict. A conflict resolves once; a booking
  /// that is not part of it is a failure.
  Future<Either<Failure, CalendarConflictEntity>> resolveConflict({
    required String conflictId,
    required String keepBookingId,
  });
}
