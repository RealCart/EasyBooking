import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

/// Validates the account form and creates the account of a new user.
///
/// The form validates too, for immediate feedback; this check keeps the
/// rule in the domain for every caller.
final class CreateAccountUsecase
    implements
        Usecase<Future<Either<Failure, void>>, CreateAccountParamsEntity> {
  const CreateAccountUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(CreateAccountParamsEntity params) async {
    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String email = params.email.trim();
    final String teamName = params.teamName.trim();

    final Map<String, String> fieldErrors = <String, String>{
      if (firstName.isEmpty) AccountFields.firstName: AuthErrorCodes.required,
      if (lastName.isEmpty) AccountFields.lastName: AuthErrorCodes.required,
      if (email.isEmpty)
        AccountFields.email: AuthErrorCodes.required
      else if (!Validators.isValidEmail(email))
        AccountFields.email: AuthErrorCodes.invalidEmail,
      if (teamName.isEmpty) AccountFields.teamName: AuthErrorCodes.required,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, void>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.createAccount(
      CreateAccountParamsEntity(
        firstName: firstName,
        lastName: lastName,
        email: email,
        teamName: teamName,
        city: params.city,
      ),
    );
  }
}
