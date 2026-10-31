import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/form_validators.dart';

void main() {
  group('FormValidators.required', () {
    test('rejects null, empty and blank values', () {
      for (final String? value in <String?>[null, '', '   ', '\n\t']) {
        expect(
          FormValidators.required(value),
          FormValidators.requiredMessage,
          reason: '$value',
        );
      }
    });

    test('accepts any non-blank value', () {
      expect(FormValidators.required(' a '), isNull);
    });
  });

  group('FormValidators.email', () {
    test('a blank email is required rather than invalid', () {
      expect(FormValidators.email('  '), FormValidators.requiredMessage);
      expect(FormValidators.email(null), FormValidators.requiredMessage);
    });

    test('rejects a malformed email', () {
      expect(
        FormValidators.email('aigerim@'),
        FormValidators.invalidEmailMessage,
      );
    });

    test('accepts a valid email with surrounding spaces', () {
      expect(FormValidators.email(' aigerim@example.kz '), isNull);
    });
  });

  group('FormValidators.phone', () {
    test('accepts a complete Kazakhstan number in any format', () {
      for (final String value in <String>[
        '700 123 45 67',
        '+7 (700) 123-45-67',
        '87001234567',
      ]) {
        expect(FormValidators.phone(value), isNull, reason: value);
      }
    });

    test('rejects an incomplete or foreign number', () {
      for (final String? value in <String?>[null, '', '700123', '6001234567']) {
        expect(
          FormValidators.phone(value),
          FormValidators.invalidPhoneMessage,
          reason: '$value',
        );
      }
    });
  });

  group('FormValidators.otp', () {
    test('accepts exactly six digits', () {
      expect(FormValidators.otp('482913'), isNull);
    });

    test('rejects an incomplete or non-digit code', () {
      for (final String? value in <String?>[null, '', '12345', '12345a']) {
        expect(
          FormValidators.otp(value),
          FormValidators.incompleteOtpMessage,
          reason: '$value',
        );
      }
    });
  });

  group('FormValidators.selected', () {
    test('requires a value', () {
      expect(FormValidators.selected(null), FormValidators.requiredMessage);
      expect(FormValidators.selected(Object()), isNull);
    });
  });
}
