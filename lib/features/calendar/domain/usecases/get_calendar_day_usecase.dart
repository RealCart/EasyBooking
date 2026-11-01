import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_repository.dart';

final class GetCalendarDayUsecase
    implements
        Usecase<
          Future<Either<Failure, CalendarDayEntity>>,
          CalendarDayParamsEntity
        > {
  const GetCalendarDayUsecase(this._repository);

  final CalendarRepository _repository;

  @override
  Future<Either<Failure, CalendarDayEntity>> call(
    CalendarDayParamsEntity params,
  ) {
    return _repository.getDay(
      date: params.date,
      favoritesOnly: params.favoritesOnly,
    );
  }
}
