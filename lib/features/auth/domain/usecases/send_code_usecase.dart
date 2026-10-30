import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

/// Sends an SMS code to a phone number in any user-typed format.
final class SendCodeUsecase
    implements Usecase<Future<Either<Failure, OtpChallengeEntity>>, String> {
  const SendCodeUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, OtpChallengeEntity>> call(String params) async {
    final String? phone = PhoneNumber.toE164(params);
    if (phone == null) {
      return const Left<Failure, OtpChallengeEntity>(
        ValidationFailure(code: AuthErrorCodes.invalidPhone),
      );
    }
    return _repository.sendCode(phone);
  }
}
