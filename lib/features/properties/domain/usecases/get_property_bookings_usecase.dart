import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

final class GetPropertyBookingsUsecase
    implements
        Usecase<
          Future<Either<Failure, PropertyBookingsEntity>>,
          GetPropertyParamsEntity
        > {
  const GetPropertyBookingsUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, PropertyBookingsEntity>> call(
    GetPropertyParamsEntity params,
  ) {
    return _repository.getBookings(params.propertyId);
  }
}
