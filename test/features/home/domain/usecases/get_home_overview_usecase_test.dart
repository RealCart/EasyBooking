import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';

import '../../../../helpers/fake_home_repository.dart';

void main() {
  group('GetHomeOverviewUsecase', () {
    test('returns the overview of the repository', () async {
      final FakeHomeRepository repository = FakeHomeRepository();

      final Either<Failure, HomeOverviewEntity> result =
          await GetHomeOverviewUsecase(repository)(const NoParams());

      expect(result, Right<Failure, HomeOverviewEntity>(testHomeOverview()));
      expect(repository.overviewCount, 1);
    });

    test('passes a repository failure through unchanged', () async {
      const Failure failure = ConnectionFailure();
      final FakeHomeRepository repository = FakeHomeRepository()
        ..overviewResult = const Left<Failure, HomeOverviewEntity>(failure);

      final Either<Failure, HomeOverviewEntity> result =
          await GetHomeOverviewUsecase(repository)(const NoParams());

      expect(result, const Left<Failure, HomeOverviewEntity>(failure));
    });
  });
}
