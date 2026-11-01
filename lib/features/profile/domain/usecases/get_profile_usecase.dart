import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetProfileUsecase
    implements Usecase<Future<Either<Failure, ProfileEntity>>, NoParams> {
  const GetProfileUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, ProfileEntity>> call(NoParams params) {
    return _repository.getProfile();
  }
}
