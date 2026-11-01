import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_property_settings_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// Saves the property settings and returns them as stored.
final class SavePropertySettingsUsecase
    implements
        Usecase<
          Future<Either<Failure, PropertySettingsEntity>>,
          SavePropertySettingsParamsEntity
        > {
  const SavePropertySettingsUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, PropertySettingsEntity>> call(
    SavePropertySettingsParamsEntity params,
  ) {
    return _repository.saveSettings(
      propertyId: params.propertyId,
      acceptsBookings: params.acceptsBookings,
    );
  }
}
