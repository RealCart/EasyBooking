import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// Served by a mock source until the properties API exists.
abstract interface class PropertiesRepository {
  /// Every property of the user, in the order the source returns them.
  Future<Either<Failure, List<PropertyEntity>>> getProperties();

  /// The property [id]; an unknown id is a failure.
  Future<Either<Failure, PropertyEntity>> getProperty(String id);

  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  });
}
