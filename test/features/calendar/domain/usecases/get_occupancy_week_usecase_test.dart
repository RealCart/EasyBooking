import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';

import '../../../../helpers/fake_occupancy_repository.dart';

void main() {
  group('GetOccupancyWeekUsecase', () {
    test('forwards the date and scope and returns the week', () async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      final DateTime date = DateTime(2026, 10, 28);

      final Either<Failure, OccupancyWeekEntity> result =
          await GetOccupancyWeekUsecase(repository)(
            OccupancyWeekParamsEntity(date: date, favoritesOnly: true),
          );

      expect(repository.requests.single, (date: date, favoritesOnly: true));
      expect(
        result,
        Right<Failure, OccupancyWeekEntity>(
          testOccupancyWeek(DateTime(2026, 10, 26)),
        ),
      );
    });

    test('no date asks for the current week', () async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();

      await GetOccupancyWeekUsecase(
        repository,
      )(const OccupancyWeekParamsEntity(favoritesOnly: false));

      expect(repository.requests.single, (date: null, favoritesOnly: false));
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = ServerFailure(statusCode: 500);
      final FakeOccupancyRepository repository = FakeOccupancyRepository()
        ..weekFailure = failure;

      expect(
        await GetOccupancyWeekUsecase(
          repository,
        )(const OccupancyWeekParamsEntity(favoritesOnly: false)),
        const Left<Failure, OccupancyWeekEntity>(failure),
      );
    });
  });
}
