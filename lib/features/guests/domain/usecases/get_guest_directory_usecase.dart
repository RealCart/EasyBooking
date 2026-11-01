import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_directory_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';

final class GetGuestDirectoryUsecase
    implements
        Usecase<
          Future<Either<Failure, GuestDirectoryEntity>>,
          GetGuestDirectoryParamsEntity
        > {
  const GetGuestDirectoryUsecase(this._repository);

  final GuestsRepository _repository;

  /// Surrounding spaces are not part of the query, so `' '` is the default
  /// view.
  @override
  Future<Either<Failure, GuestDirectoryEntity>> call(
    GetGuestDirectoryParamsEntity params,
  ) {
    return _repository.getDirectory(params.query.trim());
  }
}
