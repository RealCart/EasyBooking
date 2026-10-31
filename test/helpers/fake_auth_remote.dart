import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';

/// [AuthRemote] that records every call and answers with the configured
/// models, or with the configured `*Failure` as `Either.left`.
final class FakeAuthRemote implements AuthRemote {
  int resendAfterSeconds = 30;
  VerifyCodeResponseModel verifyResponse = const VerifyCodeResponseModel(
    accessToken: 'access',
    refreshToken: 'refresh',
    isNewUser: false,
  );

  Failure? sendCodeFailure;
  Failure? verifyCodeFailure;
  Failure? createAccountFailure;

  /// Thrown by [sendCode] instead of answering, to simulate a programming
  /// defect.
  Error? sendCodeError;

  final List<String> sentPhones = <String>[];
  final List<({String phone, String code})> verifyCalls =
      <({String phone, String code})>[];
  final List<CreateAccountRequestModel> createAccountRequests =
      <CreateAccountRequestModel>[];

  @override
  Future<Either<Failure, OtpChallengeModel>> sendCode(String phone) async {
    sentPhones.add(phone);
    if (sendCodeError case final Error error) {
      throw error;
    }
    if (sendCodeFailure case final Failure failure) {
      return Either<Failure, OtpChallengeModel>.left(failure);
    }
    return Either<Failure, OtpChallengeModel>.right(
      OtpChallengeModel(resendAfterSeconds: resendAfterSeconds),
    );
  }

  @override
  Future<Either<Failure, VerifyCodeResponseModel>> verifyCode({
    required String phone,
    required String code,
  }) async {
    verifyCalls.add((phone: phone, code: code));
    if (verifyCodeFailure case final Failure failure) {
      return Either<Failure, VerifyCodeResponseModel>.left(failure);
    }
    return Either<Failure, VerifyCodeResponseModel>.right(verifyResponse);
  }

  @override
  Future<Either<Failure, void>> createAccount(
    CreateAccountRequestModel request,
  ) async {
    createAccountRequests.add(request);
    if (createAccountFailure case final Failure failure) {
      return Either<Failure, void>.left(failure);
    }
    return const Either<Failure, void>.right(null);
  }
}
