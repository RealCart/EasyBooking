import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

/// Remote calls followed by the matching [AuthSession] update. The session
/// changes only after the request succeeded; a storage failure while saving
/// it is returned as `StorageFailure`.
///
/// Sources and the session already return `Either`, so the repository only
/// maps models to entities and chains the steps.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remote,
    required this._session,
  });

  final AuthRemote _remote;
  final AuthSession _session;

  @override
  Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone) async {
    final Either<Failure, OtpChallengeModel> result = await _remote.sendCode(
      phone,
    );
    return result.map(
      (OtpChallengeModel model) => model.toEntity(phone: phone),
    );
  }

  @override
  Future<Either<Failure, void>> verifyCode({
    required String phone,
    required String code,
  }) async {
    final Either<Failure, VerifyCodeResponseModel> result = await _remote
        .verifyCode(phone: phone, code: code);
    return result.flatMapAsync(
      (VerifyCodeResponseModel response) => _session.signIn(
        response.toTokens(),
        isAccountSetupPending: response.isNewUser,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> createAccount(
    CreateAccountParamsEntity params,
  ) async {
    final Either<Failure, void> result = await _remote.createAccount(
      CreateAccountRequestModel.fromEntity(params),
    );
    return result.flatMapAsync((_) async {
      await _session.completeAccountSetup();
      return const Either<Failure, void>.right(null);
    });
  }

  @override
  Future<Either<Failure, void>> signOut() => _session.signOut();
}
