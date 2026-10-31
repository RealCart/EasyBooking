import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/app_api.dart';
import 'package:easy_booking/core/utils/network/interceptors/auth_interceptor.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';

/// Auth endpoints. Transport, status, and parsing errors arrive as
/// `Either.left` from [ApiClient].
abstract interface class AuthRemote {
  /// [phone] is in E.164 format.
  Future<Either<Failure, OtpChallengeModel>> sendCode(String phone);

  Future<Either<Failure, VerifyCodeResponseModel>> verifyCode({
    required String phone,
    required String code,
  });

  /// Requires a signed-in session; the response body is ignored.
  Future<Either<Failure, void>> createAccount(
    CreateAccountRequestModel request,
  );
}

final class AuthRemoteImpl implements AuthRemote {
  const AuthRemoteImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<Either<Failure, OtpChallengeModel>> sendCode(String phone) {
    return _apiClient.post(
      AppApi.sendCode,
      data: <String, Object?>{AppApi.phoneKey: phone},
      options: _skipAuthOptions(),
      parse: jsonObject(OtpChallengeModel.fromJson),
    );
  }

  @override
  Future<Either<Failure, VerifyCodeResponseModel>> verifyCode({
    required String phone,
    required String code,
  }) {
    return _apiClient.post(
      AppApi.verifyCode,
      data: <String, Object?>{AppApi.phoneKey: phone, AppApi.codeKey: code},
      options: _skipAuthOptions(),
      parse: jsonObject(VerifyCodeResponseModel.fromJson),
    );
  }

  @override
  Future<Either<Failure, void>> createAccount(
    CreateAccountRequestModel request,
  ) {
    return _apiClient.post<void>(
      AppApi.account,
      data: request.toJson(),
      parse: (_) {},
    );
  }

  /// Sending and verifying the code happen before sign-in, so no bearer
  /// token is attached and a 401 does not close a session.
  static Options _skipAuthOptions() {
    return Options(extra: <String, Object?>{AuthInterceptor.skipAuthKey: true});
  }
}
