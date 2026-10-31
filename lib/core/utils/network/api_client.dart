import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_mapper.dart';

/// Turns a response body into a model. May throw `ParsingException` or
/// `CheckedFromJsonException`; [ApiClient] returns them as `ParsingFailure`.
typedef ResponseParser<T> = T Function(Object? data);

/// A [ResponseParser] for a JSON object body read with [fromJson]. Any other
/// body (a list, a string, `null`) is a `ParsingFailure`.
ResponseParser<T> jsonObject<T>(
  T Function(Map<String, dynamic> json) fromJson,
) {
  return (Object? data) {
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Expected a JSON object, got ${data.runtimeType}');
    }
    return fromJson(data);
  };
}

/// Shared HTTP client used by every remote source.
///
/// Every call completes with `Either.right` holding the parsed body, or
/// `Either.left` with a [Failure]: transport and status errors are mapped by
/// `ErrorInterceptor`, parsing errors by the client itself. Only an `Error`
/// (a programming defect) is thrown.
abstract interface class ApiClient {
  Future<Either<Failure, T>> get<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, T>> post<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, T>> put<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, T>> patch<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, T>> delete<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Releases the connection pool. Called by the DI container only.
  void close();
}

final class ApiClientImpl implements ApiClient {
  const ApiClientImpl({required this._dio});

  final Dio _dio;

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _send(
      _dio.get<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
      parse,
    );
  }

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _send(
      _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parse,
    );
  }

  @override
  Future<Either<Failure, T>> put<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _send(
      _dio.put<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parse,
    );
  }

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _send(
      _dio.patch<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parse,
    );
  }

  @override
  Future<Either<Failure, T>> delete<T>(
    String path, {
    required ResponseParser<T> parse,
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _send(
      _dio.delete<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parse,
    );
  }

  @override
  void close() => _dio.close();

  /// The single place where a request's outcome becomes an [Either].
  static Future<Either<Failure, T>> _send<T>(
    Future<Response<Object?>> request,
    ResponseParser<T> parse,
  ) async {
    final Response<Object?> response;
    try {
      response = await request;
    } on DioException catch (exception, stackTrace) {
      // `ErrorInterceptor` stores the failure. Errors that skip the
      // interceptors, such as a request cancelled before it was sent, are
      // mapped here.
      return Either<Failure, T>.left(switch (exception.error) {
        final Failure failure => failure,
        _ => mapExceptionToFailure(exception, stackTrace),
      });
    }
    try {
      return Either<Failure, T>.right(parse(response.data));
    } on Exception catch (exception, stackTrace) {
      return Either<Failure, T>.left(
        mapExceptionToFailure(exception, stackTrace),
      );
    }
  }
}
