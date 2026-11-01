import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/resolve_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_conflicts_repository.dart';

final class ResolveCalendarConflictUsecase
    implements
        Usecase<
          Future<Either<Failure, CalendarConflictEntity>>,
          ResolveCalendarConflictParamsEntity
        > {
  const ResolveCalendarConflictUsecase(this._repository);

  final CalendarConflictsRepository _repository;

  @override
  Future<Either<Failure, CalendarConflictEntity>> call(
    ResolveCalendarConflictParamsEntity params,
  ) {
    return _repository.resolveConflict(
      conflictId: params.conflictId,
      keepBookingId: params.keepBookingId,
    );
  }
}
