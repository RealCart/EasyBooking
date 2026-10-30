import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_mapper.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';

/// Remote calls followed by the matching [AuthSession] update. The session
/// changes only after the request succeeded; a storage failure while saving
/// it is returned as `StorageFailure`.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remote,
    required this._session,
  });

  final AuthRemote _remote;
  final AuthSession _session;

  @override
  Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone) {
    return runGuarded<OtpChallengeEntity>(() async {
      final OtpChallengeModel model = await _remote.sendCode(phone);
      return model.toEntity(phone: phone);
    });
  }

  @override
  Future<Either<Failure, void>> verifyCode({
    required String phone,
    required String code,
  }) {
    return runGuarded<void>(() async {
      final VerifyCodeResponseModel response = await _remote.verifyCode(
        phone: phone,
        code: code,
      );
      await _session.signIn(
        response.toTokens(),
        isAccountSetupPending: response.isNewUser,
      );
    });
  }

  @override
  Future<Either<Failure, void>> createAccount(CreateAccountParams params) {
    return runGuarded<void>(() async {
      await _remote.createAccount(
        CreateAccountRequestModel.fromParams(params),
      );
      await _session.completeAccountSetup();
    });
  }

  @override
  Future<Either<Failure, void>> signOut() {
    return runGuarded<void>(_session.signOut);
  }
}
