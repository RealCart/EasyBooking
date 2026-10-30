import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';

void main() {
  group('Failure.userMessage', () {
    const String technical = 'SocketException: 10.0.0.1 secret-token';

    final Map<Failure, String> expected = <Failure, String>{
      const ConnectionFailure(message: technical):
          'Нет подключения к интернету',
      const TimeoutFailure(message: technical):
          'Сервер долго не отвечает. Попробуйте ещё раз',
      const CancelledFailure(message: technical): 'Запрос отменён',
      const UnauthorizedFailure(message: technical):
          'Сессия истекла. Войдите снова',
      const ValidationFailure(message: technical): 'Проверьте введённые данные',
      const ServerFailure(statusCode: 500, message: technical):
          'Сервис временно недоступен. Попробуйте позже',
      const ParsingFailure(message: technical):
          'Не удалось обработать ответ сервера',
      const StorageFailure(message: technical):
          'Не удалось сохранить данные на устройстве',
      const UnexpectedFailure(message: technical):
          'Что-то пошло не так. Попробуйте ещё раз',
    };

    expected.forEach((Failure failure, String message) {
      test('${failure.runtimeType} shows a localized text', () {
        expect(failure.userMessage, message);
      });
    });

    test('never exposes the technical message', () {
      for (final Failure failure in expected.keys) {
        expect(failure.userMessage, isNot(contains(technical)));
      }
    });
  });

  group('Failure equality', () {
    test('same type and fields are equal', () {
      expect(
        const ServerFailure(statusCode: 500, code: 'x', message: 'm'),
        const ServerFailure(statusCode: 500, code: 'x', message: 'm'),
      );
      expect(
        const ValidationFailure(fieldErrors: <String, String>{'a': 'b'}),
        const ValidationFailure(fieldErrors: <String, String>{'a': 'b'}),
      );
    });

    test('different fields or types are not equal', () {
      expect(
        const ServerFailure(statusCode: 500),
        isNot(equals(const ServerFailure(statusCode: 502))),
      );
      expect(
        const ServerFailure(statusCode: 500, code: 'a'),
        isNot(equals(const ServerFailure(statusCode: 500, code: 'b'))),
      );
      expect(
        const ValidationFailure(code: 'a'),
        isNot(equals(const ValidationFailure(code: 'b'))),
      );
      expect(
        const ValidationFailure(fieldErrors: <String, String>{'a': 'b'}),
        isNot(
          equals(
            const ValidationFailure(fieldErrors: <String, String>{'a': 'c'}),
          ),
        ),
      );
      expect(
        const ConnectionFailure(message: 'm'),
        isNot(equals(const TimeoutFailure(message: 'm'))),
      );
    });
  });
}
