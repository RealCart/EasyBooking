import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/verify_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

/// Checks the SMS code and signs the user in.
final class VerifyCodeUsecase
    implements Usecase<Future<Either<Failure, void>>, VerifyCodeParamsEntity> {
  const VerifyCodeUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(VerifyCodeParamsEntity params) async {
    if (!Validators.isValidOtp(params.code)) {
      return const Left<Failure, void>(
        ValidationFailure(code: AuthErrorCodes.invalidCode),
      );
    }
    return _repository.verifyCode(phone: params.phone, code: params.code);
  }
}
