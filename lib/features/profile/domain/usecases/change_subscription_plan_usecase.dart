import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/change_subscription_plan_params_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Switches the subscription plan and returns the updated overview. A plan
/// whose limits the workspace already exceeds is refused with
/// `ProfileErrorCodes.planLimitExceeded`.
final class ChangeSubscriptionPlanUsecase
    implements
        Usecase<
          Future<Either<Failure, BillingOverviewEntity>>,
          ChangeSubscriptionPlanParamsEntity
        > {
  const ChangeSubscriptionPlanUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, BillingOverviewEntity>> call(
    ChangeSubscriptionPlanParamsEntity params,
  ) {
    return _repository.changePlan(params.plan);
  }
}
