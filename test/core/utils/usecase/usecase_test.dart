import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';

final class _DoubleUsecase
    implements Usecase<Future<Either<Failure, int>>, int> {
  const _DoubleUsecase();

  @override
  Future<Either<Failure, int>> call(int params) async {
    if (params < 0) {
      return const Left<Failure, int>(ValidationFailure(code: 'negative'));
    }
    return Right<Failure, int>(params * 2);
  }
}

final class _GreetingUsecase implements Usecase<String, NoParams> {
  const _GreetingUsecase();

  @override
  String call(NoParams params) => 'hello';
}

void main() {
  group('Usecase', () {
    test('a concrete usecase is callable with its params type', () async {
      const Usecase<Future<Either<Failure, int>>, int> usecase =
          _DoubleUsecase();

      expect(await usecase(4), const Right<Failure, int>(8));
      expect(
        await usecase(-1),
        const Left<Failure, int>(ValidationFailure(code: 'negative')),
      );
    });

    test('a usecase without input takes NoParams', () {
      const Usecase<String, NoParams> usecase = _GreetingUsecase();

      expect(usecase(const NoParams()), 'hello');
    });
  });

  group('NoParams', () {
    test('has value equality with no fields', () {
      expect(const NoParams(), equals(const NoParams()));
      expect(const NoParams().props, isEmpty);
    });
  });
}
