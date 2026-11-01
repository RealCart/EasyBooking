import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_conflicts_repository.dart';

final class GetCalendarConflictUsecase
    implements
        Usecase<
          Future<Either<Failure, CalendarConflictEntity>>,
          GetCalendarConflictParamsEntity
        > {
  const GetCalendarConflictUsecase(this._repository);

  final CalendarConflictsRepository _repository;

  @override
  Future<Either<Failure, CalendarConflictEntity>> call(
    GetCalendarConflictParamsEntity params,
  ) {
    return _repository.getConflict(params.conflictId);
  }
}
