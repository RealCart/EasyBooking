import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/set_biometric_login_params_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Switches «Вход по Face ID» and returns the updated overview.
final class SetBiometricLoginUsecase
    implements
        Usecase<
          Future<Either<Failure, SecurityOverviewEntity>>,
          SetBiometricLoginParamsEntity
        > {
  const SetBiometricLoginUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, SecurityOverviewEntity>> call(
    SetBiometricLoginParamsEntity params,
  ) {
    return _repository.setBiometricLogin(isEnabled: params.isEnabled);
  }
}
