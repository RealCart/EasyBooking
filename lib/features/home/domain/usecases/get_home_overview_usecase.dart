import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/repository/home_repository.dart';

final class GetHomeOverviewUsecase
    implements Usecase<Future<Either<Failure, HomeOverviewEntity>>, NoParams> {
  const GetHomeOverviewUsecase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeOverviewEntity>> call(NoParams params) {
    return _repository.getOverview();
  }
}
