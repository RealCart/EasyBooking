import 'package:json_annotation/json_annotation.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';

part 'verify_code_response_model.g.dart';

/// Response of `POST /auth/otp/verify`.
///
/// `fromJson` throws `CheckedFromJsonException` when a token or `isNewUser`
/// is missing or has the wrong type. Its message never includes token values.
@JsonSerializable(checked: true, createToJson: false)
final class VerifyCodeResponseModel {
  const VerifyCodeResponseModel({
    required this.accessToken,
    required this.isNewUser,
    this.refreshToken,
  });

  factory VerifyCodeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$VerifyCodeResponseModelFromJson(json);

  @JsonKey(required: true, fromJson: _nonEmptyString)
  final String accessToken;

  final String? refreshToken;

  /// The user has no account yet and must finish account setup.
  @JsonKey(required: true)
  final bool isNewUser;

  AuthTokens toTokens() {
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  // Keeps tokens out of logs and error reports.
  @override
  String toString() => 'VerifyCodeResponseModel(isNewUser: $isNewUser)';
}

String _nonEmptyString(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const ParsingException('must be a non-empty String');
  }
  return value;
}
