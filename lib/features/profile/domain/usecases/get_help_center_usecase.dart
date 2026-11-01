import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetHelpCenterUsecase
    implements Usecase<Future<Either<Failure, HelpCenterEntity>>, NoParams> {
  const GetHelpCenterUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, HelpCenterEntity>> call(NoParams params) {
    return _repository.getHelpCenter();
  }
}
