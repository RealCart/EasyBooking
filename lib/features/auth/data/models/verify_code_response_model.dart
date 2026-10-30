import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';

/// Response of `POST /auth/otp/verify`.
final class VerifyCodeResponseModel {
  const VerifyCodeResponseModel({
    required this.accessToken,
    required this.isNewUser,
    this.refreshToken,
  });

  /// Throws [ParsingException] when the tokens or `isNewUser` have the wrong
  /// type. The messages never include token values.
  factory VerifyCodeResponseModel.fromJson(Map<String, Object?> json) {
    final Object? accessToken = json[_accessTokenKey];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ParsingException(
        'VerifyCodeResponse: accessToken must be a non-empty String',
      );
    }
    final String? refreshToken = switch (json[_refreshTokenKey]) {
      null => null,
      final String value => value,
      _ => throw const ParsingException(
        'VerifyCodeResponse: refreshToken must be a String or null',
      ),
    };
    final Object? isNewUser = json[_isNewUserKey];
    if (isNewUser is! bool) {
      throw const ParsingException(
        'VerifyCodeResponse: isNewUser must be a bool',
      );
    }
    return VerifyCodeResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      isNewUser: isNewUser,
    );
  }

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _isNewUserKey = 'isNewUser';

  final String accessToken;
  final String? refreshToken;

  /// The user has no account yet and must finish account setup.
  final bool isNewUser;

  AuthTokens toTokens() {
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  // Keeps tokens out of logs and error reports.
  @override
  String toString() => 'VerifyCodeResponseModel(isNewUser: $isNewUser)';
}
