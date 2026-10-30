import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/money_formatter.dart';

const String _nbsp = ' ';

void main() {
  group('MoneyFormatter.group', () {
    test('groups digits by three with a no-break space', () {
      expect(MoneyFormatter.group(0), '0');
      expect(MoneyFormatter.group(7), '7');
      expect(MoneyFormatter.group(999), '999');
      expect(MoneyFormatter.group(1000), '1${_nbsp}000');
      expect(MoneyFormatter.group(42500), '42${_nbsp}500');
      expect(MoneyFormatter.group(100000), '100${_nbsp}000');
      expect(MoneyFormatter.group(1250000), '1${_nbsp}250${_nbsp}000');
    });

    test('never uses a regular space', () {
      expect(MoneyFormatter.group(1234567890), isNot(contains(' ')));
    });

    test('prefixes negative amounts with a minus sign', () {
      expect(MoneyFormatter.group(-5), '−5');
      expect(MoneyFormatter.group(-1250000), '−1${_nbsp}250${_nbsp}000');
      expect(MoneyFormatter.group(-1000), isNot(contains('-')));
    });
  });

  group('MoneyFormatter.tenge', () {
    test('appends the tenge sign after a no-break space', () {
      expect(MoneyFormatter.tenge(42500), '42${_nbsp}500$_nbsp₸');
      expect(MoneyFormatter.tenge(0), '0$_nbsp₸');
      expect(MoneyFormatter.tenge(-300), '−300$_nbsp₸');
    });

    test('tengePerNight keeps the amount and unit on one line', () {
      expect(
        MoneyFormatter.tengePerNight(42500),
        '42${_nbsp}500$_nbsp₸$_nbsp/ ночь',
      );
    });
  });
}
