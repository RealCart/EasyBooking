import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('otpLength is 6', () {
      expect(Validators.otpLength, 6);
    });

    test('isNotBlank rejects null, empty and whitespace', () {
      expect(Validators.isNotBlank(null), isFalse);
      expect(Validators.isNotBlank(''), isFalse);
      expect(Validators.isNotBlank('  \n\t'), isFalse);
      expect(Validators.isNotBlank(' a '), isTrue);
    });

    test('isValidEmail accepts common addresses and trims spaces', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('first.last+tag@mail.example.kz'), isTrue);
      expect(Validators.isValidEmail('  user@example.com  '), isTrue);
    });

    test('isValidEmail rejects malformed addresses', () {
      for (final String value in <String>[
        '',
        'user',
        'user@',
        '@example.com',
        'user@example',
        'user@@example.com',
        'user name@example.com',
      ]) {
        expect(Validators.isValidEmail(value), isFalse, reason: value);
      }
    });

    test('isValidPhone accepts complete Kazakhstan numbers only', () {
      expect(Validators.isValidPhone('+7 700 123 45 67'), isTrue);
      expect(Validators.isValidPhone('87001234567'), isTrue);
      expect(Validators.isValidPhone('700 123 45'), isFalse);
      expect(Validators.isValidPhone('0000000000'), isFalse);
    });

    test('isValidOtp requires exactly six ASCII digits', () {
      expect(Validators.isValidOtp('123456'), isTrue);
      expect(Validators.isValidOtp('000000'), isTrue);
      expect(Validators.isValidOtp('12345'), isFalse);
      expect(Validators.isValidOtp('1234567'), isFalse);
      expect(Validators.isValidOtp('12345a'), isFalse);
      expect(Validators.isValidOtp('123 45'), isFalse);
      expect(Validators.isValidOtp('１２３４５６'), isFalse);
    });
  });
}
