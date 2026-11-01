import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/remove_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Revokes a member's access and returns the updated team. The owner cannot
/// be removed (`ProfileErrorCodes.cannotRemoveOwner`).
final class RemoveTeamMemberUsecase
    implements
        Usecase<
          Future<Either<Failure, List<TeamMemberEntity>>>,
          RemoveTeamMemberParamsEntity
        > {
  const RemoveTeamMemberUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> call(
    RemoveTeamMemberParamsEntity params,
  ) {
    return _repository.removeTeamMember(params.memberId);
  }
}
