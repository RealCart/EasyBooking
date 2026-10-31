import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/network/app_api.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';

/// Adds the bearer token and closes the session when the server answers 401.
///
/// Requests made before sign-in (sending or verifying the SMS code) must opt
/// out with `Options(extra: {AuthInterceptor.skipAuthKey: true})`.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._session});

  static const String skipAuthKey = 'skipAuth';

  final AuthSession _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final AuthTokens? tokens = _session.tokens;
    if (!_skipsAuth(options) && tokens != null) {
      options.headers[AppApi.authorizationHeader] = _bearer(tokens);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && _usedCurrentToken(err)) {
      final Either<Failure, void> result = await _session.signOut();
      if (result case Left<Failure, void>(value: final Failure failure)) {
        AppLogger.warning(
          'Session closed in memory but tokens were not cleared',
          error: failure,
        );
      }
    }
    handler.next(err);
  }

  bool _skipsAuth(RequestOptions options) {
    return options.extra[skipAuthKey] == true;
  }

  // A late 401 for a request sent with an older token must not close a
  // session that was opened after it.
  bool _usedCurrentToken(DioException err) {
    final AuthTokens? tokens = _session.tokens;
    return tokens != null &&
        err.requestOptions.headers[AppApi.authorizationHeader] ==
            _bearer(tokens);
  }

  String _bearer(AuthTokens tokens) {
    return '${AppApi.bearerScheme} ${tokens.accessToken}';
  }
}
