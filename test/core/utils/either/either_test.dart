import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';

void main() {
  group('Either', () {
    test('Left reports isLeft and not isRight', () {
      const Either<String, int> value = Either<String, int>.left('error');

      expect(value, isA<Left<String, int>>());
      expect(value.isLeft, isTrue);
      expect(value.isRight, isFalse);
    });

    test('Right reports isRight and not isLeft', () {
      const Either<String, int> value = Either<String, int>.right(1);

      expect(value, isA<Right<String, int>>());
      expect(value.isRight, isTrue);
      expect(value.isLeft, isFalse);
    });

    test('Right with a null payload is still a Right', () {
      const Either<String, void> value = Either<String, void>.right(null);
      const Either<String?, int> left = Either<String?, int>.left(null);

      expect(value.isRight, isTrue);
      expect(left.isLeft, isTrue);
    });

    test('fold on Left calls only onLeft', () {
      const Either<String, int> value = Left<String, int>('error');
      final List<String> calls = <String>[];

      final String result = value.fold(
        (String left) {
          calls.add('left');
          return 'L:$left';
        },
        (int right) {
          calls.add('right');
          return 'R:$right';
        },
      );

      expect(result, 'L:error');
      expect(calls, <String>['left']);
    });

    test('fold on Right calls only onRight', () {
      const Either<String, int> value = Right<String, int>(5);
      final List<String> calls = <String>[];

      final String result = value.fold(
        (String left) {
          calls.add('left');
          return 'L:$left';
        },
        (int right) {
          calls.add('right');
          return 'R:$right';
        },
      );

      expect(result, 'R:5');
      expect(calls, <String>['right']);
    });

    test(
      'fold returns the async callback future for the caller to await',
      () async {
        const Either<String, int> value = Right<String, int>(2);

        final Future<int> result = value.fold(
          (String left) async => 0,
          (int right) async => right * 10,
        );

        expect(await result, 20);
      },
    );

    test('map transforms Right and keeps Left untouched', () {
      const Either<String, int> right = Right<String, int>(2);
      const Either<String, int> left = Left<String, int>('error');
      int calls = 0;

      final Either<String, String> mappedRight = right.map((int value) {
        calls++;
        return 'v$value';
      });
      final Either<String, String> mappedLeft = left.map((int value) {
        calls++;
        return 'v$value';
      });

      expect(mappedRight, const Right<String, String>('v2'));
      expect(mappedLeft, const Left<String, String>('error'));
      expect(calls, 1);
    });

    test('mapLeft transforms Left and keeps Right untouched', () {
      const Either<String, int> right = Right<String, int>(2);
      const Either<String, int> left = Left<String, int>('error');

      expect(
        left.mapLeft((String value) => value.length),
        const Left<int, int>(5),
      );
      expect(
        right.mapLeft((String value) => value.length),
        const Right<int, int>(2),
      );
    });

    test('flatMap chains Right and short-circuits on Left', () {
      const Either<String, int> right = Right<String, int>(2);
      const Either<String, int> left = Left<String, int>('error');
      int calls = 0;

      Either<String, int> half(int value) {
        calls++;
        return value.isEven
            ? Right<String, int>(value ~/ 2)
            : const Left<String, int>('odd');
      }

      expect(right.flatMap(half), const Right<String, int>(1));
      expect(
        const Right<String, int>(3).flatMap(half),
        const Left<String, int>('odd'),
      );
      expect(left.flatMap(half), const Left<String, int>('error'));
      expect(calls, 2);
    });

    test('equal payloads on the same branch are equal', () {
      expect(const Left<String, int>('a'), const Left<String, int>('a'));
      expect(const Right<String, int>(1), const Right<String, int>(1));
      expect(
        const Right<String, int>(1).hashCode,
        const Right<String, int>(1).hashCode,
      );
    });

    test('different branches or payloads are not equal', () {
      expect(
        const Left<int, int>(1),
        isNot(equals(const Right<int, int>(1))),
      );
      expect(
        const Right<String, int>(1),
        isNot(equals(const Right<String, int>(2))),
      );
    });
  });
}
