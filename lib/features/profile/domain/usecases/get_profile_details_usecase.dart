import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetProfileDetailsUsecase
    implements
        Usecase<Future<Either<Failure, ProfileDetailsEntity>>, NoParams> {
  const GetProfileDetailsUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, ProfileDetailsEntity>> call(NoParams params) {
    return _repository.getProfileDetails();
  }
}
