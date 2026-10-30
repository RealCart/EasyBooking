import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/plural.dart';

String _nights(int count) {
  return Plural.select(count, one: 'ночь', few: 'ночи', many: 'ночей');
}

void main() {
  group('Plural.select', () {
    test('uses "one" for counts ending in 1 except 11', () {
      for (final int count in <int>[1, 21, 31, 101, 121, 1001]) {
        expect(_nights(count), 'ночь', reason: '$count');
      }
    });

    test('uses "few" for counts ending in 2–4 except 12–14', () {
      for (final int count in <int>[2, 3, 4, 22, 23, 24, 102, 1004]) {
        expect(_nights(count), 'ночи', reason: '$count');
      }
    });

    test('uses "many" for 0, 5–20 and counts ending in 11–14', () {
      for (final int count in <int>[
        0,
        5,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        20,
        25,
        100,
        111,
        112,
        113,
        114,
        1011,
      ]) {
        expect(_nights(count), 'ночей', reason: '$count');
      }
    });

    test('negative counts agree like their absolute value', () {
      expect(_nights(-1), 'ночь');
      expect(_nights(-3), 'ночи');
      expect(_nights(-11), 'ночей');
      expect(_nights(-21), 'ночь');
    });
  });

  group('Plural.format', () {
    test('prefixes the count to the agreeing form', () {
      String format(int count) {
        return Plural.format(count, one: 'ночь', few: 'ночи', many: 'ночей');
      }

      expect(format(1), '1 ночь');
      expect(format(3), '3 ночи');
      expect(format(5), '5 ночей');
      expect(format(11), '11 ночей');
      expect(format(21), '21 ночь');
      expect(format(0), '0 ночей');
      expect(format(-2), '-2 ночи');
    });
  });
}
