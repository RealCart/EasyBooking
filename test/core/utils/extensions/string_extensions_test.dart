import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/extensions/string_extensions.dart';

void main() {
  group('StringExtensions.initials', () {
    test('takes the first letters of the first two words', () {
      expect('Айжан Сарсенова'.initials, 'АС');
      expect('John Ronald Tolkien'.initials, 'JR');
    });

    test('uppercases and ignores extra whitespace', () {
      expect('  айжан \t  сарсенова \n'.initials, 'АС');
    });

    test('a single word gives one initial', () {
      expect('Madina'.initials, 'M');
    });

    test('empty or blank text gives an empty string', () {
      expect(''.initials, '');
      expect('   '.initials, '');
    });

    test('keeps a non-BMP first character intact', () {
      expect('😀 Bob'.initials, '😀B');
    });
  });
}
