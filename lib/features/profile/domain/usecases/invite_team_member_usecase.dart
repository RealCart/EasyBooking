import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/field_error_codes.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Validates the invitation and sends it; returns the updated team.
///
/// Field problems come back as `ValidationFailure.fieldErrors`
/// (`ProfileFields` keys); an owner role as `ValidationFailure.code`
/// `ProfileErrorCodes.ownerRoleNotAssignable`. The source may also answer
/// with `ProfileErrorCodes.alreadyInTeam` (phone field) or
/// `ProfileErrorCodes.teamLimitReached` (code).
final class InviteTeamMemberUsecase
    implements
        Usecase<
          Future<Either<Failure, List<TeamMemberEntity>>>,
          InviteTeamMemberParamsEntity
        > {
  const InviteTeamMemberUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> call(
    InviteTeamMemberParamsEntity params,
  ) async {
    if (params.role == ProfileRole.owner) {
      return const Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(code: ProfileErrorCodes.ownerRoleNotAssignable),
      );
    }

    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String? phone = Validators.isValidPhone(params.phone)
        ? PhoneNumber.toE164(params.phone)
        : null;

    final Map<String, String> fieldErrors = <String, String>{
      if (firstName.isEmpty) ProfileFields.firstName: FieldErrorCodes.required,
      if (lastName.isEmpty) ProfileFields.lastName: FieldErrorCodes.required,
      if (phone == null) ProfileFields.phone: FieldErrorCodes.invalidPhone,
    };
    if (phone == null || fieldErrors.isNotEmpty) {
      return Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.inviteTeamMember(
      InviteTeamMemberParamsEntity(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: params.role,
      ),
    );
  }
}
