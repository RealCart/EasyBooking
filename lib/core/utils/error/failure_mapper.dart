import 'dart:io';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/error/error_response_model.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';

/// Converts an exception caught at the repository boundary to a [Failure].
///
/// Repositories call it from `on Exception catch (exception, stackTrace)`,
/// so an [Error] (a programming defect) is never caught and keeps
/// propagating. An exception that no failure describes is logged with
/// [stackTrace] and returned as [UnexpectedFailure].
Failure mapExceptionToFailure(Exception exception, [StackTrace? stackTrace]) {
  final Failure failure = _mapException(exception);
  if (failure is UnexpectedFailure) {
    AppLogger.error(
      'Unexpected exception in data layer',
      error: exception,
      stackTrace: stackTrace,
    );
  }
  return failure;
}

Failure _mapException(Exception exception) {
  return switch (exception) {
    DioException() => _mapDioException(exception),
    ParsingException(:final String message) => ParsingFailure(message: message),
    StorageException(:final String message) => StorageFailure(message: message),
    FormatException(:final String message) => ParsingFailure(message: message),
    // Thrown by generated `fromJson` of `@JsonSerializable(checked: true)`
    // models. Only the class, key, and error text are kept: `map` holds the
    // raw values, which may be tokens.
    CheckedFromJsonException(
      :final String? className,
      :final String? key,
      :final String? message,
    ) =>
      ParsingFailure(message: '$className.$key: $message'),
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
        return _mapException(cause);
      }
      return UnexpectedFailure(message: message);
  }
}

Failure _mapBadResponse(Response<Object?>? response) {
  final int? statusCode = response?.statusCode;
  final ErrorResponseModel body = ErrorResponseModel.parse(response?.data);

  if (statusCode == 401) {
    return UnauthorizedFailure(message: body.message);
  }
  if (statusCode == 400 || statusCode == 422) {
    return ValidationFailure(
      code: body.code,
      fieldErrors: body.errors,
      message: body.message,
    );
  }
  return ServerFailure(
    statusCode: statusCode,
    code: body.code,
    message: body.message,
  );
}
