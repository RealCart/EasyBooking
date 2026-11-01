import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

/// Reads from [PropertiesMockLocal], which already returns entities. The
/// mock has no single-property call, so [getProperty] picks it from the
/// list.
final class PropertiesRepositoryImpl implements PropertiesRepository {
  const PropertiesRepositoryImpl({required this._local});

  final PropertiesMockLocal _local;

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties() {
    return _local.loadProperties();
  }

  @override
  Future<Either<Failure, PropertyEntity>> getProperty(String id) async {
    final Either<Failure, List<PropertyEntity>> result = await _local
        .loadProperties();
    return result.flatMap((List<PropertyEntity> properties) {
      for (final PropertyEntity property in properties) {
        if (property.id == id) {
          return Right<Failure, PropertyEntity>(property);
        }
      }
      return Left<Failure, PropertyEntity>(
        ServerFailure(statusCode: 404, message: 'Unknown property $id'),
      );
    });
  }

  @override
  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  }) {
    return _local.setFavorite(propertyId: propertyId, isFavorite: isFavorite);
  }
}
