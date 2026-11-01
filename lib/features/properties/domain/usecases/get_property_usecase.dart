import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

final class GetPropertyUsecase
    implements
        Usecase<
          Future<Either<Failure, PropertyEntity>>,
          GetPropertyParamsEntity
        > {
  const GetPropertyUsecase(this._repository);

  final PropertiesRepository _repository;

  @override
  Future<Either<Failure, PropertyEntity>> call(GetPropertyParamsEntity params) {
    return _repository.getProperty(params.propertyId);
  }
}
