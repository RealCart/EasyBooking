import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetBillingOverviewUsecase
    implements
        Usecase<Future<Either<Failure, BillingOverviewEntity>>, NoParams> {
  const GetBillingOverviewUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, BillingOverviewEntity>> call(NoParams params) {
    return _repository.getBillingOverview();
  }
}
