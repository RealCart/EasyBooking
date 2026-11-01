import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/set_property_favorite_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

final class SetPropertyFavoriteUsecase
    implements
        Usecase<
          Future<Either<Failure, void>>,
          SetPropertyFavoriteParamsEntity
        > {
  const SetPropertyFavoriteUsecase(this._repository);

  final PropertiesRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetPropertyFavoriteParamsEntity params) {
    return _repository.setFavorite(
      propertyId: params.propertyId,
      isFavorite: params.isFavorite,
    );
  }
}
