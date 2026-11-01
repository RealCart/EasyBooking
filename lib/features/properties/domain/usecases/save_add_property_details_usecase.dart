import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// Validates step 1 of «Добавить квартиру» and saves it to the draft.
///
/// The form validates too, for immediate feedback; this check keeps the
/// rule in the domain for every caller.
final class SaveAddPropertyDetailsUsecase
    implements
        Usecase<
          Future<Either<Failure, void>>,
          SaveAddPropertyDetailsParamsEntity
        > {
  const SaveAddPropertyDetailsUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    SaveAddPropertyDetailsParamsEntity params,
  ) async {
    final String title = params.title.trim();
    final String address = params.address.trim();

    final Map<String, String> fieldErrors = <String, String>{
      if (!Validators.isNotBlank(title))
        AddPropertyFields.title: PropertyErrorCodes.required,
      if (!Validators.isNotBlank(address))
        AddPropertyFields.address: PropertyErrorCodes.required,
      if (params.rooms < PropertyLimits.minRooms ||
          params.rooms > PropertyLimits.maxRooms)
        AddPropertyFields.rooms: PropertyErrorCodes.outOfRange,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, void>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.saveAddPropertyDetails(
      SaveAddPropertyDetailsParamsEntity(
        title: title,
        address: address,
        type: params.type,
        rooms: params.rooms,
      ),
    );
  }
}
