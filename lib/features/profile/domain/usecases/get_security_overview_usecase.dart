import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetSecurityOverviewUsecase
    implements
        Usecase<Future<Either<Failure, SecurityOverviewEntity>>, NoParams> {
  const GetSecurityOverviewUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, SecurityOverviewEntity>> call(NoParams params) {
    return _repository.getSecurityOverview();
  }
}
