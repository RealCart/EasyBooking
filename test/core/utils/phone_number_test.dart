import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/phone_number.dart';

void main() {
  group('PhoneNumber.toNational', () {
    test('accepts ten national digits and +7, 7 or 8 prefixes', () {
      for (final String input in <String>[
        '7001234567',
        '+7 700 123 45 67',
        '+77001234567',
        '77001234567',
        '87001234567',
        '8 (700) 123-45-67',
      ]) {
        expect(PhoneNumber.toNational(input), '7001234567', reason: input);
      }
    });

    test('returns null for incomplete or too long input', () {
      for (final String input in <String>[
        '',
        '700',
        '700123456',
        '770012345678',
        '+7 700 123 45',
      ]) {
        expect(PhoneNumber.toNational(input), isNull, reason: input);
      }
    });

    test('returns null for 11 digits with a foreign prefix', () {
      expect(PhoneNumber.toNational('17001234567'), isNull);
      expect(PhoneNumber.toNational('97001234567'), isNull);
    });

    test('requires the national number to start with 7', () {
      expect(PhoneNumber.toNational('0000000000'), isNull);
      expect(PhoneNumber.toNational('9001234567'), isNull);
      expect(PhoneNumber.toNational('+7 900 123 45 67'), isNull);
    });
  });

  group('PhoneNumber.nationalDigits', () {
    test('keeps partial input as typed', () {
      expect(PhoneNumber.nationalDigits(''), '');
      expect(PhoneNumber.nationalDigits('700 12'), '70012');
      expect(PhoneNumber.nationalDigits('8700'), '8700');
    });

    test('strips a 7 or 8 trunk prefix from a full 11-digit number', () {
      expect(PhoneNumber.nationalDigits('+7 700 123 45 67'), '7001234567');
      expect(PhoneNumber.nationalDigits('87001234567'), '7001234567');
    });

    test('limits other input to ten digits', () {
      expect(PhoneNumber.nationalDigits('17001234567'), '1700123456');
      expect(PhoneNumber.nationalDigits('700123456789'), '7001234567');
    });
  });

  group('PhoneNumber.hasTrunkPrefix', () {
    test('is true only for 11 digits starting with 7 or 8', () {
      expect(PhoneNumber.hasTrunkPrefix('77001234567'), isTrue);
      expect(PhoneNumber.hasTrunkPrefix('87001234567'), isTrue);
      expect(PhoneNumber.hasTrunkPrefix('17001234567'), isFalse);
      expect(PhoneNumber.hasTrunkPrefix('7001234567'), isFalse);
      expect(PhoneNumber.hasTrunkPrefix('770012345678'), isFalse);
    });
  });

  group('PhoneNumber.toE164', () {
    test('returns +7 and the national digits', () {
      expect(PhoneNumber.toE164('8 700 123 45 67'), '+77001234567');
      expect(PhoneNumber.toE164('7001234567'), '+77001234567');
    });

    test('returns null for an invalid number', () {
      expect(PhoneNumber.toE164('700 123'), isNull);
    });
  });

  group('PhoneNumber.format', () {
    test('formats a complete number with the country code', () {
      expect(PhoneNumber.format('87001234567'), '+7 700 123 45 67');
      expect(PhoneNumber.format('+77001234567'), '+7 700 123 45 67');
    });

    test('returns incomplete or unknown input unchanged', () {
      expect(PhoneNumber.format('700 12'), '700 12');
      expect(PhoneNumber.format('+1 555 0100'), '+1 555 0100');
    });
  });

  group('PhoneNumber.formatNational', () {
    test('groups partial input as 3-3-2-2', () {
      expect(PhoneNumber.formatNational(''), '');
      expect(PhoneNumber.formatNational('7'), '7');
      expect(PhoneNumber.formatNational('700'), '700');
      expect(PhoneNumber.formatNational('7001'), '700 1');
      expect(PhoneNumber.formatNational('700123'), '700 123');
      expect(PhoneNumber.formatNational('7001234'), '700 123 4');
      expect(PhoneNumber.formatNational('70012345'), '700 123 45');
      expect(PhoneNumber.formatNational('700123456'), '700 123 45 6');
      expect(PhoneNumber.formatNational('7001234567'), '700 123 45 67');
    });

    test('ignores non-digits and extra digits', () {
      expect(PhoneNumber.formatNational('(700) 12-3'), '700 123');
      expect(PhoneNumber.formatNational('700123456789'), '700 123 45 67');
    });

    test('drops the prefix of a pasted full number', () {
      expect(PhoneNumber.formatNational('+7 700 123 45 67'), '700 123 45 67');
    });
  });

  test('digitsOnly removes everything but ASCII digits', () {
    expect(PhoneNumber.digitsOnly('+7 (700) 123-45-67'), '77001234567');
    expect(PhoneNumber.digitsOnly('abc'), '');
  });
}
