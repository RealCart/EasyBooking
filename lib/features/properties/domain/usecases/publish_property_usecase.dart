import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/publish_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// Validates the terms of step 3 and publishes the add-property draft.
/// Returns the new property's id.
///
/// The form validates too, for immediate feedback; this check keeps the
/// rule in the domain for every caller.
final class PublishPropertyUsecase
    implements
        Usecase<Future<Either<Failure, String>>, PublishPropertyParamsEntity> {
  const PublishPropertyUsecase(this._repository);

  final PropertyManagementRepository _repository;

  static const Duration _day = Duration(days: 1);

  @override
  Future<Either<Failure, String>> call(PublishPropertyParamsEntity params) {
    final PropertyTermsEntity terms = params.terms;

    final Map<String, String> fieldErrors = <String, String>{
      if (terms.pricePerNight <= 0)
        AddPropertyFields.pricePerNight: PropertyErrorCodes.outOfRange,
      if (terms.deposit < 0)
        AddPropertyFields.deposit: PropertyErrorCodes.outOfRange,
      if (!_isTimeOfDay(terms.checkInTime))
        AddPropertyFields.checkInTime: PropertyErrorCodes.outOfRange,
      if (!_isTimeOfDay(terms.checkOutTime))
        AddPropertyFields.checkOutTime: PropertyErrorCodes.outOfRange,
      if (terms.minNights < PropertyLimits.minNights ||
          terms.minNights > PropertyLimits.maxMinNights)
        AddPropertyFields.minNights: PropertyErrorCodes.outOfRange,
      if (terms.cleaningFee < 0)
        AddPropertyFields.cleaningFee: PropertyErrorCodes.outOfRange,
    };
    if (fieldErrors.isNotEmpty) {
      return Future<Either<Failure, String>>.value(
        Left<Failure, String>(
          ValidationFailure(
            fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
          ),
        ),
      );
    }

    return _repository.publishProperty(terms);
  }

  /// Within one day, in whole minutes.
  static bool _isTimeOfDay(Duration time) {
    return !time.isNegative &&
        time < _day &&
        time.inMicroseconds % Duration.microsecondsPerMinute == 0;
  }
}
