import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/data/repository/home_repository_impl.dart';
import 'package:easy_booking/features/home/data/sources/local/home_mock_local.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';

import '../../../../helpers/fake_home_repository.dart';

final class _FakeHomeMockLocal implements HomeMockLocal {
  _FakeHomeMockLocal(this.result);

  final Either<Failure, HomeOverviewEntity> Function() result;
  int loadCount = 0;

  @override
  Future<Either<Failure, HomeOverviewEntity>> loadOverview() async {
    loadCount += 1;
    return result();
  }
}

void main() {
  group('HomeRepositoryImpl.getOverview', () {
    test('returns the overview of the source', () async {
      final HomeOverviewEntity overview = testHomeOverview();
      final _FakeHomeMockLocal local = _FakeHomeMockLocal(
        () => Right<Failure, HomeOverviewEntity>(overview),
      );

      final Either<Failure, HomeOverviewEntity> result =
          await HomeRepositoryImpl(local: local).getOverview();

      expect(result, Right<Failure, HomeOverviewEntity>(overview));
      expect(local.loadCount, 1);
    });

    test('passes a source failure through unchanged', () async {
      const Failure failure = StorageFailure(message: 'disk');
      final _FakeHomeMockLocal local = _FakeHomeMockLocal(
        () => const Left<Failure, HomeOverviewEntity>(failure),
      );

      final Either<Failure, HomeOverviewEntity> result =
          await HomeRepositoryImpl(local: local).getOverview();

      expect(result, const Left<Failure, HomeOverviewEntity>(failure));
    });

    test('lets an Error of the source propagate', () async {
      final _FakeHomeMockLocal local = _FakeHomeMockLocal(
        () => throw StateError('defect'),
      );

      expect(
        HomeRepositoryImpl(local: local).getOverview(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
