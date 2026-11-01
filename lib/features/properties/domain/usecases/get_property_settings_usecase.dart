import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

final class GetPropertySettingsUsecase
    implements
        Usecase<
          Future<Either<Failure, PropertySettingsEntity>>,
          GetPropertyParamsEntity
        > {
  const GetPropertySettingsUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, PropertySettingsEntity>> call(
    GetPropertyParamsEntity params,
  ) {
    return _repository.getSettings(params.propertyId);
  }
}
