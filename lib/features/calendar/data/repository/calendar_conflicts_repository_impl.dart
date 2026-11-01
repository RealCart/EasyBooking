import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_conflicts_repository.dart';

/// Reads and resolves conflicts in [CalendarSyncMockLocal], which already
/// returns entities.
final class CalendarConflictsRepositoryImpl
    implements CalendarConflictsRepository {
  const CalendarConflictsRepositoryImpl({required this._local});

  final CalendarSyncMockLocal _local;

  @override
  Future<Either<Failure, CalendarConflictEntity>> getConflict(String id) {
    return _local.loadConflict(id);
  }

  @override
  Future<Either<Failure, CalendarConflictEntity>> resolveConflict({
    required String conflictId,
    required String keepBookingId,
  }) {
    return _local.resolveConflict(
      conflictId: conflictId,
      keepBookingId: keepBookingId,
    );
  }
}
