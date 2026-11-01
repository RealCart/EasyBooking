import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/field_error_codes.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Validates the «Редактировать профиль» form and saves it.
///
/// The form validates too, for immediate feedback; this check keeps the
/// rule in the domain for every caller. A failure carries
/// `ProfileFields` keys mapped to `FieldErrorCodes` field codes.
final class UpdateProfileUsecase
    implements
        Usecase<
          Future<Either<Failure, ProfileDetailsEntity>>,
          UpdateProfileParamsEntity
        > {
  const UpdateProfileUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, ProfileDetailsEntity>> call(
    UpdateProfileParamsEntity params,
  ) async {
    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String email = params.email.trim();
    final String teamName = params.teamName.trim();

    final Map<String, String> fieldErrors = <String, String>{
      if (firstName.isEmpty) ProfileFields.firstName: FieldErrorCodes.required,
      if (lastName.isEmpty) ProfileFields.lastName: FieldErrorCodes.required,
      if (email.isEmpty)
        ProfileFields.email: FieldErrorCodes.required
      else if (!Validators.isValidEmail(email))
        ProfileFields.email: FieldErrorCodes.invalidEmail,
      if (teamName.isEmpty) ProfileFields.teamName: FieldErrorCodes.required,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, ProfileDetailsEntity>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.updateProfile(
      UpdateProfileParamsEntity(
        firstName: firstName,
        lastName: lastName,
        email: email,
        teamName: teamName,
        city: params.city,
      ),
    );
  }
}
