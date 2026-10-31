import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';

abstract interface class AuthRepository {
  /// Sends an SMS code to [phone] (E.164). Remote only.
  Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone);

  /// Checks the code and, on success, opens the session. A new user's session
  /// is marked as pending account setup.
  Future<Either<Failure, void>> verifyCode({
    required String phone,
    required String code,
  });

  /// Creates the account of a new user and, on success, completes account
  /// setup in the session. [params] must be validated.
  Future<Either<Failure, void>> createAccount(CreateAccountParamsEntity params);

  /// Closes the session locally.
  Future<Either<Failure, void>> signOut();
}
