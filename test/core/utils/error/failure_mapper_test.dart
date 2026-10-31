import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_mapper.dart';

final RequestOptions _request = RequestOptions(path: '/items');

DioException _dioError(
  DioExceptionType type, {
  String? message,
  Object? error,
}) {
  return DioException(
    requestOptions: _request,
    type: type,
    message: message,
    error: error,
  );
}

DioException _badResponse(int? statusCode, [Object? data]) {
  return DioException.badResponse(
    statusCode: statusCode ?? 0,
    requestOptions: _request,
    response: Response<Object?>(
      requestOptions: _request,
      statusCode: statusCode,
      data: data,
    ),
  );
}

final class _CustomException implements Exception {
  @override
  String toString() => 'CustomException: boom';
}

void main() {
  group('mapExceptionToFailure for DioException', () {
    for (final DioExceptionType type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      test('$type maps to TimeoutFailure with the message', () {
        expect(
          mapExceptionToFailure(_dioError(type, message: 'slow')),
          const TimeoutFailure(message: 'slow'),
        );
      });
    }

    for (final DioExceptionType type in <DioExceptionType>[
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
    ]) {
      test('$type maps to ConnectionFailure', () {
        expect(
          mapExceptionToFailure(_dioError(type, message: 'offline')),
          const ConnectionFailure(message: 'offline'),
        );
      });
    }

    test('cancel maps to CancelledFailure', () {
      expect(
        mapExceptionToFailure(
          _dioError(DioExceptionType.cancel, message: 'obsolete'),
        ),
        const CancelledFailure(message: 'obsolete'),
      );
    });

    test('401 maps to UnauthorizedFailure with the body message', () {
      expect(
        mapExceptionToFailure(
          _badResponse(401, <String, Object?>{'message': 'expired'}),
        ),
        const UnauthorizedFailure(message: 'expired'),
      );
    });

    for (final int status in <int>[400, 422]) {
      test('$status maps to ValidationFailure with code, message, errors', () {
        final Failure failure = mapExceptionToFailure(
          _badResponse(status, <String, Object?>{
            'code': 'invalid_input',
            'message': 'Check fields',
            'errors': <String, Object?>{
              'phone': 'Invalid phone',
              'email': <Object?>['Taken', 'Too long'],
            },
          }),
        );

        expect(
          failure,
          const ValidationFailure(
            code: 'invalid_input',
            message: 'Check fields',
            fieldErrors: <String, String>{
              'phone': 'Invalid phone',
              'email': 'Taken',
            },
          ),
        );
      });
    }

    test('validation errors skip values that are not strings', () {
      final Failure failure = mapExceptionToFailure(
        _badResponse(422, <String, Object?>{
          'errors': <String, Object?>{
            'number': 5,
            'emptyList': <Object?>[],
            'numberList': <Object?>[1, 'second'],
            'nested': <String, Object?>{'a': 'b'},
            'nullValue': null,
            'kept': <Object?>['first'],
          },
        }),
      );

      expect(
        failure,
        const ValidationFailure(fieldErrors: <String, String>{'kept': 'first'}),
      );
    });

    test('validation field errors are unmodifiable', () {
      final Failure failure = mapExceptionToFailure(
        _badResponse(400, <String, Object?>{
          'errors': <String, Object?>{'name': 'Required'},
        }),
      );

      expect(failure, isA<ValidationFailure>());
      final Map<String, String> fieldErrors =
          (failure as ValidationFailure).fieldErrors;
      expect(() => fieldErrors['other'] = 'x', throwsUnsupportedError);
    });

    test('malformed body fields are ignored instead of throwing', () {
      expect(
        mapExceptionToFailure(
          _badResponse(422, <String, Object?>{
            'code': 7,
            'message': <Object?>['not', 'a', 'string'],
            'errors': <Object?>['not', 'a', 'map'],
          }),
        ),
        const ValidationFailure(),
      );
    });

    test('non-map body produces a failure without details', () {
      expect(
        mapExceptionToFailure(_badResponse(400, '<html>Bad</html>')),
        const ValidationFailure(),
      );
      expect(
        mapExceptionToFailure(_badResponse(500, <Object?>['x'])),
        const ServerFailure(statusCode: 500),
      );
    });

    test('other statuses map to ServerFailure with status, code, message', () {
      expect(
        mapExceptionToFailure(
          _badResponse(503, <String, Object?>{
            'code': 'maintenance',
            'message': 'Down',
          }),
        ),
        const ServerFailure(
          statusCode: 503,
          code: 'maintenance',
          message: 'Down',
        ),
      );
      expect(
        mapExceptionToFailure(_badResponse(404)),
        const ServerFailure(statusCode: 404),
      );
    });

    test('badResponse without a response maps to ServerFailure(null)', () {
      expect(
        mapExceptionToFailure(_dioError(DioExceptionType.badResponse)),
        const ServerFailure(statusCode: null),
      );
    });

    test('unknown with an IOException cause maps to ConnectionFailure', () {
      for (final IOException cause in <IOException>[
        const SocketException('reset by peer'),
        const HttpException('connection closed'),
      ]) {
        expect(
          mapExceptionToFailure(
            _dioError(DioExceptionType.unknown, message: 'io', error: cause),
          ),
          const ConnectionFailure(message: 'io'),
          reason: '${cause.runtimeType}',
        );
      }
    });

    test('unknown with an Exception cause maps the cause', () {
      expect(
        mapExceptionToFailure(
          _dioError(
            DioExceptionType.unknown,
            error: const FormatException('bad'),
          ),
        ),
        const ParsingFailure(message: 'bad'),
      );
      expect(
        mapExceptionToFailure(
          _dioError(
            DioExceptionType.unknown,
            error: const StorageException('io'),
          ),
        ),
        const StorageFailure(message: 'io'),
      );
    });

    test('unknown with a nested DioException cause is unexpected', () {
      expect(
        mapExceptionToFailure(
          _dioError(
            DioExceptionType.unknown,
            message: 'outer',
            error: _dioError(DioExceptionType.cancel),
          ),
        ),
        const UnexpectedFailure(message: 'outer'),
      );
    });

    test('unknown with a non-Exception cause is unexpected', () {
      expect(
        mapExceptionToFailure(
          _dioError(
            DioExceptionType.unknown,
            message: 'outer',
            error: StateError('bug'),
          ),
        ),
        const UnexpectedFailure(message: 'outer'),
      );
      expect(
        mapExceptionToFailure(_dioError(DioExceptionType.unknown)),
        const UnexpectedFailure(),
      );
    });
  });

  group('mapExceptionToFailure for other exceptions', () {
    test('ParsingException maps to ParsingFailure', () {
      expect(
        mapExceptionToFailure(const ParsingException('missing id')),
        const ParsingFailure(message: 'missing id'),
      );
    });

    test('FormatException maps to ParsingFailure', () {
      expect(
        mapExceptionToFailure(const FormatException('bad date')),
        const ParsingFailure(message: 'bad date'),
      );
    });

    test('CheckedFromJsonException maps to ParsingFailure without values', () {
      final Failure failure = mapExceptionToFailure(
        CheckedFromJsonException(
          const <String, Object?>{'accessToken': 'secret-token'},
          'accessToken',
          'TokenModel',
          'must be a non-empty String',
        ),
      );

      expect(
        failure,
        const ParsingFailure(
          message: 'TokenModel.accessToken: must be a non-empty String',
        ),
      );
      expect(failure.message, isNot(contains('secret')));
    });

    test('accepts the stack trace of the catch clause', () {
      expect(
        mapExceptionToFailure(_CustomException(), StackTrace.current),
        const UnexpectedFailure(message: 'CustomException: boom'),
      );
    });

    test('StorageException maps to StorageFailure', () {
      expect(
        mapExceptionToFailure(const StorageException('locked')),
        const StorageFailure(message: 'locked'),
      );
    });

    test('any other Exception maps to UnexpectedFailure', () {
      expect(
        mapExceptionToFailure(_CustomException()),
        const UnexpectedFailure(message: 'CustomException: boom'),
      );
    });
  });
}
