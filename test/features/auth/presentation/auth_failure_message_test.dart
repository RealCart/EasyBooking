import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/core/utils/error/auth_failure_message.dart';

const String _tooMany = 'Слишком много попыток. Попробуйте позже';

void main() {
  group('AuthFailureMessage.authMessage', () {
    test('maps the auth codes of a ValidationFailure', () {
      expect(
        const ValidationFailure(code: AuthErrorCodes.invalidPhone).authMessage,
        'Проверьте номер телефона',
      );
      expect(
        const ValidationFailure(code: AuthErrorCodes.invalidCode).authMessage,
        'Неверный код',
      );
      expect(
        const ValidationFailure(code: AuthErrorCodes.codeExpired).authMessage,
        'Код истёк. Запросите новый',
      );
      expect(
        const ValidationFailure(
          code: AuthErrorCodes.tooManyRequests,
        ).authMessage,
        _tooMany,
      );
    });

    test('maps the auth codes of a ServerFailure', () {
      expect(
        const ServerFailure(
          statusCode: 400,
          code: AuthErrorCodes.codeExpired,
        ).authMessage,
        'Код истёк. Запросите новый',
      );
      expect(
        const ServerFailure(
          statusCode: 503,
          code: AuthErrorCodes.tooManyRequests,
        ).authMessage,
        _tooMany,
      );
    });

    test('a 429 is too many attempts whatever its code', () {
      expect(const ServerFailure(statusCode: 429).authMessage, _tooMany);
      expect(
        const ServerFailure(
          statusCode: 429,
          code: AuthErrorCodes.invalidCode,
        ).authMessage,
        _tooMany,
      );
    });

    test('an UnauthorizedFailure asks for a new code', () {
      expect(
        const UnauthorizedFailure().authMessage,
        'Не удалось войти. Запросите код ещё раз',
      );
    });

    test('anything else falls back to userMessage', () {
      for (final Failure failure in <Failure>[
        const ValidationFailure(),
        const ValidationFailure(code: 'unknown'),
        const ServerFailure(statusCode: 500),
        const ServerFailure(statusCode: 500, code: 'unknown'),
        const ConnectionFailure(),
        const TimeoutFailure(),
        const CancelledFailure(),
        const ParsingFailure(),
        const StorageFailure(),
        const UnexpectedFailure(),
      ]) {
        expect(failure.authMessage, failure.userMessage, reason: '$failure');
      }
    });

    test('never shows the technical message', () {
      expect(
        const ServerFailure(
          statusCode: 500,
          message: 'stack trace',
        ).authMessage,
        isNot(contains('stack trace')),
      );
    });
  });

  group('authFieldErrorMessage', () {
    test('returns null for no error', () {
      expect(authFieldErrorMessage(null), isNull);
      expect(authFieldErrorMessage(''), isNull);
    });

    test('maps the field codes', () {
      expect(
        authFieldErrorMessage(AuthErrorCodes.required),
        'Заполните поле',
      );
      expect(
        authFieldErrorMessage(AuthErrorCodes.invalidEmail),
        'Проверьте адрес почты',
      );
    });

    test('maps any other value, such as a server text, to a generic text', () {
      expect(authFieldErrorMessage('taken'), 'Проверьте поле');
      expect(authFieldErrorMessage('Email already used'), 'Проверьте поле');
    });
  });
}
