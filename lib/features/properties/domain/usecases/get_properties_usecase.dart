import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

final class GetPropertiesUsecase
    implements
        Usecase<Future<Either<Failure, List<PropertyEntity>>>, NoParams> {
  const GetPropertiesUsecase(this._repository);

  final PropertiesRepository _repository;

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(NoParams params) {
    return _repository.getProperties();
  }
}
