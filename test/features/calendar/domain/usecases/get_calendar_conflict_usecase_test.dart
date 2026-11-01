import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';

import '../../../../helpers/fake_calendar_conflicts_repository.dart';

void main() {
  group('GetCalendarConflictUsecase', () {
    test('forwards the conflict id and returns the conflict', () async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository();

      final Either<Failure, CalendarConflictEntity> result =
          await GetCalendarConflictUsecase(
            repository,
          )(const GetCalendarConflictParamsEntity(conflictId: 'c1'));

      expect(repository.conflictRequests, <String>['c1']);
      expect(
        result,
        Right<Failure, CalendarConflictEntity>(testCalendarConflict()),
      );
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = ServerFailure(statusCode: 404);
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..conflictResult = const Left<Failure, CalendarConflictEntity>(
              failure,
            );

      expect(
        await GetCalendarConflictUsecase(
          repository,
        )(const GetCalendarConflictParamsEntity(conflictId: 'missing')),
        const Left<Failure, CalendarConflictEntity>(failure),
      );
    });
  });
}
