import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';

import '../../../../helpers/fake_profile_repository.dart';

void main() {
  group('GetProfileUsecase', () {
    test('returns the profile and passes a failure through', () async {
      final FakeProfileRepository repository = FakeProfileRepository();
      final GetProfileUsecase usecase = GetProfileUsecase(repository);

      expect(
        await usecase(const NoParams()),
        const Right<Failure, ProfileEntity>(testProfile),
      );

      repository.profileResult = const Left<Failure, ProfileEntity>(
        ConnectionFailure(),
      );
      expect(
        await usecase(const NoParams()),
        const Left<Failure, ProfileEntity>(ConnectionFailure()),
      );
      expect(repository.profileCount, 2);
    });
  });
}
