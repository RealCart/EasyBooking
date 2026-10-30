import 'dart:io';

import 'package:dio/dio.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';

/// Runs a data-layer [action] and converts expected exceptions to a [Failure].
///
/// Use it in repository implementations, the only place where exceptions
/// become `Either.left`. Only [Exception]s are converted: an [Error] means a
/// programming defect and keeps propagating.
Future<Either<Failure, T>> runGuarded<T>(Future<T> Function() action) async {
  try {
    return Either<Failure, T>.right(await action());
  } on Exception catch (exception, stackTrace) {
    final Failure failure = mapExceptionToFailure(exception);
    if (failure is UnexpectedFailure) {
      AppLogger.error(
        'Unexpected exception in data layer',
        error: exception,
        stackTrace: stackTrace,
      );
    }
    return Either<Failure, T>.left(failure);
  }
}

Failure mapExceptionToFailure(Exception exception) {
  return switch (exception) {
    DioException() => _mapDioException(exception),
    ParsingException(:final String message) => ParsingFailure(message: message),
    StorageException(:final String message) => StorageFailure(message: message),
    FormatException(:final String message) => ParsingFailure(message: message),
    _ => UnexpectedFailure(message: exception.toString()),
  };
}

Failure _mapDioException(DioException exception) {
  final String? message = exception.message;
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return TimeoutFailure(message: message);
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return ConnectionFailure(message: message);
    case DioExceptionType.cancel:
      return CancelledFailure(message: message);
    case DioExceptionType.badResponse:
      return _mapBadResponse(exception.response);
    case DioExceptionType.unknown:
      final Object? cause = exception.error;
      // Dropped connections and failed handshakes arrive here, not as
      // `connectionError`.
      if (cause is IOException) {
        return ConnectionFailure(message: message);
      }
      if (cause is Exception && cause is! DioException) {
        return mapExceptionToFailure(cause);
      }
      return UnexpectedFailure(message: message);
  }
}

Failure _mapBadResponse(Response<Object?>? response) {
  final int? statusCode = response?.statusCode;
  final _ErrorBody body = _ErrorBody.parse(response?.data);

  if (statusCode == 401) {
    return UnauthorizedFailure(message: body.message);
  }
  if (statusCode == 400 || statusCode == 422) {
    return ValidationFailure(
      code: body.code,
      fieldErrors: body.fieldErrors,
      message: body.message,
    );
  }
  return ServerFailure(
    statusCode: statusCode,
    code: body.code,
    message: body.message,
  );
}

/// Error payload read defensively from `{code, message, errors}`.
///
/// `errors` may map a field to a string or to a list of strings; only the
/// first string is kept. Unknown shapes produce empty values.
final class _ErrorBody {
  const _ErrorBody({
    this.code,
    this.message,
    this.fieldErrors = const <String, String>{},
  });

  factory _ErrorBody.parse(Object? data) {
    if (data is! Map<String, Object?>) {
      return const _ErrorBody();
    }
    final Object? code = data['code'];
    final Object? message = data['message'];
    return _ErrorBody(
      code: code is String ? code : null,
      message: message is String ? message : null,
      fieldErrors: _parseFieldErrors(data['errors']),
    );
  }

  final String? code;
  final String? message;
  final Map<String, String> fieldErrors;

  static Map<String, String> _parseFieldErrors(Object? errors) {
    if (errors is! Map<String, Object?>) {
      return const <String, String>{};
    }
    final Map<String, String> result = <String, String>{};
    for (final MapEntry<String, Object?>(:String key, :Object? value)
        in errors.entries) {
      final String? text = switch (value) {
        final String text => text,
        [final String first, ...] => first,
        _ => null,
      };
      if (text != null) {
        result[key] = text;
      }
    }
    return Map<String, String>.unmodifiable(result);
  }
}
