import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetTeamUsecase
    implements
        Usecase<Future<Either<Failure, List<TeamMemberEntity>>>, NoParams> {
  const GetTeamUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> call(NoParams params) {
    return _repository.getTeam();
  }
}
