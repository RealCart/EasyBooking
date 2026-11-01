import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/resolve_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';

import '../../../../helpers/fake_calendar_conflicts_repository.dart';

void main() {
  group('ResolveCalendarConflictUsecase', () {
    test('forwards the conflict and the kept booking', () async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository();

      final Either<Failure, CalendarConflictEntity> result =
          await ResolveCalendarConflictUsecase(repository)(
            const ResolveCalendarConflictParamsEntity(
              conflictId: 'c1',
              keepBookingId: conflictTestDirectBookingId,
            ),
          );

      expect(repository.resolveRequests.single, (
        conflictId: 'c1',
        keepBookingId: conflictTestDirectBookingId,
      ));
      expect(
        result,
        Right<Failure, CalendarConflictEntity>(
          testCalendarConflict(keptBookingId: conflictTestDirectBookingId),
        ),
      );
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = ServerFailure(statusCode: 409);
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..resolveResult = const Left<Failure, CalendarConflictEntity>(
              failure,
            );

      expect(
        await ResolveCalendarConflictUsecase(repository)(
          const ResolveCalendarConflictParamsEntity(
            conflictId: 'c1',
            keepBookingId: conflictTestAirbnbBookingId,
          ),
        ),
        const Left<Failure, CalendarConflictEntity>(failure),
      );
    });
  });
}
