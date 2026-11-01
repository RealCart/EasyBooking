import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/field_error_codes.dart';
import 'package:easy_booking/core/utils/error/field_error_message.dart';

void main() {
  group('fieldErrorMessage', () {
    test('returns null for no error', () {
      expect(fieldErrorMessage(null), isNull);
      expect(fieldErrorMessage(''), isNull);
    });

    test('maps the shared field codes', () {
      expect(fieldErrorMessage(FieldErrorCodes.required), 'Заполните поле');
      expect(
        fieldErrorMessage(FieldErrorCodes.invalidEmail),
        'Проверьте адрес почты',
      );
      expect(
        fieldErrorMessage(FieldErrorCodes.invalidPhone),
        'Проверьте номер телефона',
      );
    });

    test('maps any other value, such as a server text, to a generic text', () {
      expect(fieldErrorMessage('taken'), 'Проверьте поле');
      expect(fieldErrorMessage('Email already used'), 'Проверьте поле');
    });
  });

  group('FieldErrorCodes', () {
    test('keeps the API strings', () {
      expect(FieldErrorCodes.required, 'required');
      expect(FieldErrorCodes.invalidEmail, 'invalid_email');
      expect(FieldErrorCodes.invalidPhone, 'invalid_phone');
    });
  });
}
