import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/repository/calendar_conflicts_repository_impl.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';

import '../../../../helpers/fake_calendar_conflicts_repository.dart';
import '../../../../helpers/fake_calendar_sync_mock_local.dart';

void main() {
  group('CalendarConflictsRepositoryImpl', () {
    late FakeCalendarSyncMockLocal local;
    late CalendarConflictsRepositoryImpl repository;

    setUp(() {
      local = FakeCalendarSyncMockLocal();
      repository = CalendarConflictsRepositoryImpl(local: local);
    });

    test('getConflict forwards the id and returns the conflict', () async {
      expect(
        await repository.getConflict('c1'),
        Right<Failure, CalendarConflictEntity>(testCalendarConflict()),
      );
      expect(local.conflictRequests, <String>['c1']);
    });

    test('getConflict passes a failure through', () async {
      const Failure failure = ServerFailure(statusCode: 404, message: 'gone');
      local.conflictResult = const Left<Failure, CalendarConflictEntity>(
        failure,
      );

      expect(
        await repository.getConflict('c9'),
        const Left<Failure, CalendarConflictEntity>(failure),
      );
    });

    test('resolveConflict forwards both ids and returns the result', () async {
      expect(
        await repository.resolveConflict(
          conflictId: 'c1',
          keepBookingId: conflictTestAirbnbBookingId,
        ),
        Right<Failure, CalendarConflictEntity>(
          testCalendarConflict(keptBookingId: conflictTestAirbnbBookingId),
        ),
      );
      expect(local.resolveRequests.single, (
        conflictId: 'c1',
        keepBookingId: conflictTestAirbnbBookingId,
      ));
    });

    test('resolveConflict passes a failure through', () async {
      const Failure failure = ServerFailure(statusCode: 409);
      local.resolveResult = const Left<Failure, CalendarConflictEntity>(
        failure,
      );

      expect(
        await repository.resolveConflict(
          conflictId: 'c1',
          keepBookingId: conflictTestDirectBookingId,
        ),
        const Left<Failure, CalendarConflictEntity>(failure),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getConflict('c1'), throwsStateError);
      await expectLater(
        repository.resolveConflict(conflictId: 'c1', keepBookingId: 'b1'),
        throwsStateError,
      );
    });
  });
}
