import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_mapper.dart';

/// Converts every failed request into a [Failure] stored as the
/// [DioException.error], which `ApiClient` returns as `Either.left`.
///
/// Add it after the interceptors that inspect the original error (such as
/// `AuthInterceptor`, which reacts to a 401).
final class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Failure failure = mapExceptionToFailure(err, err.stackTrace);
    handler.next(err.copyWith(error: failure));
  }
}
