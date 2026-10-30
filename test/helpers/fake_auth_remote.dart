import 'package:dio/dio.dart';

import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';

/// [AuthRemote] that records every call and answers with the configured
/// models, or throws the configured exception.
final class FakeAuthRemote implements AuthRemote {
  int resendAfterSeconds = 30;
  VerifyCodeResponseModel verifyResponse = const VerifyCodeResponseModel(
    accessToken: 'access',
    refreshToken: 'refresh',
    isNewUser: false,
  );

  Exception? sendCodeError;
  Exception? verifyCodeError;
  Exception? createAccountError;

  final List<String> sentPhones = <String>[];
  final List<({String phone, String code})> verifyCalls =
      <({String phone, String code})>[];
  final List<CreateAccountRequestModel> createAccountRequests =
      <CreateAccountRequestModel>[];

  @override
  Future<OtpChallengeModel> sendCode(String phone) async {
    sentPhones.add(phone);
    if (sendCodeError case final Exception error) {
      throw error;
    }
    return OtpChallengeModel(resendAfterSeconds: resendAfterSeconds);
  }

  @override
  Future<VerifyCodeResponseModel> verifyCode({
    required String phone,
    required String code,
  }) async {
    verifyCalls.add((phone: phone, code: code));
    if (verifyCodeError case final Exception error) {
      throw error;
    }
    return verifyResponse;
  }

  @override
  Future<void> createAccount(CreateAccountRequestModel request) async {
    createAccountRequests.add(request);
    if (createAccountError case final Exception error) {
      throw error;
    }
  }
}

/// A `DioException` for an HTTP error status with an optional JSON [data]
/// body, as Dio throws it for a non-2xx response.
DioException badResponse(int statusCode, [Object? data]) {
  final RequestOptions options = RequestOptions(path: '/test');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}
