import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SignOutUsecase usecase;

  setUp(() {
    repository = FakeAuthRepository();
    usecase = SignOutUsecase(repository);
  });

  group('SignOutUsecase', () {
    test('signs out through the repository', () async {
      final Either<Failure, void> result = await usecase(const NoParams());

      expect(result.isRight, isTrue);
      expect(repository.signOutCount, 1);
    });

    test('preserves a repository failure', () async {
      const Failure failure = StorageFailure(message: 'clear failed');
      repository.signOutResult = const Left<Failure, void>(failure);

      expect(
        await usecase(const NoParams()),
        const Left<Failure, void>(failure),
      );
    });
  });
}
