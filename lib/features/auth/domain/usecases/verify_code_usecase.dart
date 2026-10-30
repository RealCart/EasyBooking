import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

final class VerifyCodeParams extends Equatable {
  const VerifyCodeParams({required this.phone, required this.code});

  /// E.164 number the code was sent to.
  final String phone;

  final String code;

  @override
  List<Object?> get props => <Object?>[phone, code];
}

/// Checks the SMS code and signs the user in.
final class VerifyCodeUsecase
    implements Usecase<Future<Either<Failure, void>>, VerifyCodeParams> {
  const VerifyCodeUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(VerifyCodeParams params) async {
    if (!Validators.isValidOtp(params.code)) {
      return const Left<Failure, void>(
        ValidationFailure(code: AuthErrorCodes.invalidCode),
      );
    }
    return _repository.verifyCode(phone: params.phone, code: params.code);
  }
}
