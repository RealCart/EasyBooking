import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

final class CreateAccountParams extends Equatable {
  const CreateAccountParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.teamName,
    required this.city,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String teamName;

  /// `null` until the user picks a city; rejected by [CreateAccountUsecase].
  final CityEntity? city;

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    email,
    teamName,
    city,
  ];
}

/// Validates the account form and creates the account of a new user.
final class CreateAccountUsecase
    implements Usecase<Future<Either<Failure, void>>, CreateAccountParams> {
  const CreateAccountUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(CreateAccountParams params) async {
    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String email = params.email.trim();
    final String teamName = params.teamName.trim();
    final CityEntity? city = params.city;

    final Map<String, String> fieldErrors = <String, String>{
      if (firstName.isEmpty) AccountFields.firstName: AuthErrorCodes.required,
      if (lastName.isEmpty) AccountFields.lastName: AuthErrorCodes.required,
      if (email.isEmpty)
        AccountFields.email: AuthErrorCodes.required
      else if (!Validators.isValidEmail(email))
        AccountFields.email: AuthErrorCodes.invalidEmail,
      if (teamName.isEmpty) AccountFields.teamName: AuthErrorCodes.required,
      if (city == null) AccountFields.city: AuthErrorCodes.required,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, void>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.createAccount(
      CreateAccountParams(
        firstName: firstName,
        lastName: lastName,
        email: email,
        teamName: teamName,
        city: city,
      ),
    );
  }
}
