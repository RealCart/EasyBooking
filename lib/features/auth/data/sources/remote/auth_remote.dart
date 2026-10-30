import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/auth_interceptor.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';

/// Auth endpoints. Throws `DioException` on transport and status errors and
/// [ParsingException] when a response has an unexpected shape.
abstract interface class AuthRemote {
  /// [phone] is in E.164 format.
  Future<OtpChallengeModel> sendCode(String phone);

  Future<VerifyCodeResponseModel> verifyCode({
    required String phone,
    required String code,
  });

  /// Requires a signed-in session; the response body is ignored.
  Future<void> createAccount(CreateAccountRequestModel request);
}

final class AuthRemoteImpl implements AuthRemote {
  const AuthRemoteImpl({required this._apiClient});

  static const String _sendCodePath = '/auth/otp/send';
  static const String _verifyCodePath = '/auth/otp/verify';
  static const String _accountPath = '/auth/account';

  static const String _phoneKey = 'phone';
  static const String _codeKey = 'code';

  final ApiClient _apiClient;

  @override
  Future<OtpChallengeModel> sendCode(String phone) async {
    final Response<Object?> response = await _apiClient.post<Object?>(
      _sendCodePath,
      data: <String, Object?>{_phoneKey: phone},
      options: _skipAuthOptions(),
    );
    return OtpChallengeModel.fromJson(
      _jsonObject(response.data, 'OtpChallenge'),
    );
  }

  @override
  Future<VerifyCodeResponseModel> verifyCode({
    required String phone,
    required String code,
  }) async {
    final Response<Object?> response = await _apiClient.post<Object?>(
      _verifyCodePath,
      data: <String, Object?>{_phoneKey: phone, _codeKey: code},
      options: _skipAuthOptions(),
    );
    return VerifyCodeResponseModel.fromJson(
      _jsonObject(response.data, 'VerifyCodeResponse'),
    );
  }

  @override
  Future<void> createAccount(CreateAccountRequestModel request) async {
    await _apiClient.post<Object?>(_accountPath, data: request.toJson());
  }

  /// Sending and verifying the code happen before sign-in, so no bearer
  /// token is attached and a 401 does not close a session.
  static Options _skipAuthOptions() {
    return Options(extra: <String, Object?>{AuthInterceptor.skipAuthKey: true});
  }

  static Map<String, Object?> _jsonObject(Object? data, String name) {
    if (data is! Map<String, Object?>) {
      throw ParsingException('$name: expected a JSON object');
    }
    return data;
  }
}
