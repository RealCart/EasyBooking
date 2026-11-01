import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/occupancy_repository.dart';

final class GetOccupancyWeekUsecase
    implements
        Usecase<
          Future<Either<Failure, OccupancyWeekEntity>>,
          OccupancyWeekParamsEntity
        > {
  const GetOccupancyWeekUsecase(this._repository);

  final OccupancyRepository _repository;

  @override
  Future<Either<Failure, OccupancyWeekEntity>> call(
    OccupancyWeekParamsEntity params,
  ) {
    return _repository.getWeek(
      date: params.date,
      favoritesOnly: params.favoritesOnly,
    );
  }
}
