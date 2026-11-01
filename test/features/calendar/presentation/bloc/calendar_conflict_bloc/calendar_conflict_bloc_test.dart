import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_conflict_bloc/calendar_conflict_bloc.dart';

import '../../../../../helpers/fake_calendar_conflicts_repository.dart';

final class _Subject {
  _Subject() {
    bloc = CalendarConflictBloc(
      getConflict: GetCalendarConflictUsecase(repository),
      resolveConflict: ResolveCalendarConflictUsecase(repository),
    );
    final StreamSubscription<CalendarConflictState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeCalendarConflictsRepository repository =
      FakeCalendarConflictsRepository();
  late final CalendarConflictBloc bloc;
  final List<CalendarConflictState> states = <CalendarConflictState>[];

  Future<void> add(CalendarConflictEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads `c1` and forgets the states of the load.
  Future<void> load() async {
    await add(const CalendarConflictRequested('c1'));
    states.clear();
  }
}

final CalendarConflictState _loaded = CalendarConflictState(
  conflictId: 'c1',
  loadStatus: RequestStatus.success,
  conflict: testCalendarConflict(),
);

void main() {
  group('CalendarConflictBloc', () {
    test('starts with nothing loaded', () {
      expect(_Subject().bloc.state, const CalendarConflictState());
    });

    test('a load forwards the id and emits the conflict', () async {
      final _Subject subject = _Subject();

      await subject.add(const CalendarConflictRequested('c1'));

      expect(subject.repository.conflictRequests, <String>['c1']);
      expect(subject.states, <CalendarConflictState>[
        const CalendarConflictState(
          conflictId: 'c1',
          loadStatus: RequestStatus.loading,
        ),
        _loaded,
      ]);
    });

    test(
      'a failed load keeps the id, and a retry clears the failure',
      () async {
        final _Subject subject = _Subject();
        subject.repository.conflictResult =
            const Left<Failure, CalendarConflictEntity>(
              ServerFailure(statusCode: 404),
            );

        await subject.add(const CalendarConflictRequested('c1'));

        expect(
          subject.bloc.state,
          const CalendarConflictState(
            conflictId: 'c1',
            loadStatus: RequestStatus.failure,
            loadFailure: ServerFailure(statusCode: 404),
          ),
        );

        subject.repository.conflictResult =
            Right<Failure, CalendarConflictEntity>(testCalendarConflict());
        await subject.add(
          CalendarConflictRequested(subject.bloc.state.conflictId),
        );

        expect(subject.states[2].loadFailure, isNull);
        expect(subject.bloc.state, _loaded);
      },
    );

    test('keeping a booking before the conflict loads is ignored', () async {
      final _Subject subject = _Subject();

      await subject.add(
        const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
      );

      expect(subject.repository.resolveRequests, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('keeping a booking resolves the conflict', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(
        const CalendarConflictBookingKept(conflictTestDirectBookingId),
      );

      expect(subject.repository.resolveRequests.single, (
        conflictId: 'c1',
        keepBookingId: conflictTestDirectBookingId,
      ));
      expect(subject.states, <CalendarConflictState>[
        _loaded.copyWith(
          resolveStatus: RequestStatus.loading,
          keepingBookingId: conflictTestDirectBookingId,
        ),
        _loaded.copyWith(
          resolveStatus: RequestStatus.success,
          conflict: testCalendarConflict(
            keptBookingId: conflictTestDirectBookingId,
          ),
        ),
      ]);
      expect(subject.bloc.state.keepingBookingId, isNull);
    });

    test('keeping a booking after the resolve is ignored', () async {
      final _Subject subject = _Subject();
      await subject.load();
      await subject.add(
        const CalendarConflictBookingKept(conflictTestDirectBookingId),
      );

      await subject.add(
        const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
      );

      expect(subject.repository.resolveRequests, hasLength(1));
      expect(
        subject.bloc.state.conflict!.keptBookingId,
        conflictTestDirectBookingId,
      );
    });

    test('a conflict loaded already resolved cannot be resolved', () async {
      final _Subject subject = _Subject();
      subject.repository.conflictResult =
          Right<Failure, CalendarConflictEntity>(
            testCalendarConflict(keptBookingId: conflictTestAirbnbBookingId),
          );
      await subject.load();

      await subject.add(
        const CalendarConflictBookingKept(conflictTestDirectBookingId),
      );

      expect(subject.repository.resolveRequests, isEmpty);
    });

    test(
      'a failed resolve resets the kept booking and a retry clears it',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.resolveResult =
            const Left<Failure, CalendarConflictEntity>(
              ServerFailure(statusCode: 409),
            );

        await subject.add(
          const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
        );

        expect(
          subject.bloc.state,
          _loaded.copyWith(
            resolveStatus: RequestStatus.failure,
            resolveFailure: const ServerFailure(statusCode: 409),
          ),
        );

        subject.repository.resolveResult = null;
        await subject.add(
          const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
        );

        expect(subject.states[2].resolveFailure, isNull);
        expect(subject.states[2].keepingBookingId, conflictTestAirbnbBookingId);
        expect(subject.bloc.state.resolveStatus, RequestStatus.success);
        expect(subject.bloc.state.resolveFailure, isNull);
      },
    );

    test('a second keep while resolving is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdResolve = true;

      await subject.add(
        const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
      );
      await subject.add(
        const CalendarConflictBookingKept(conflictTestDirectBookingId),
      );

      expect(subject.repository.resolveRequests, hasLength(1));
      expect(subject.bloc.state.keepingBookingId, conflictTestAirbnbBookingId);

      subject.repository.heldResolves.single.complete(
        Right<Failure, CalendarConflictEntity>(
          testCalendarConflict(keptBookingId: conflictTestAirbnbBookingId),
        ),
      );
      await pumpEventQueue();

      expect(
        subject.bloc.state.conflict!.keptBookingId,
        conflictTestAirbnbBookingId,
      );
    });

    test('a resolve finishing after close is dropped without errors', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdResolve = true;
      await subject.add(
        const CalendarConflictBookingKept(conflictTestAirbnbBookingId),
      );

      await subject.bloc.close();
      subject.repository.heldResolves.single.complete(
        Right<Failure, CalendarConflictEntity>(
          testCalendarConflict(keptBookingId: conflictTestAirbnbBookingId),
        ),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
      expect(subject.bloc.state.conflict!.isResolved, isFalse);
    });
  });
}
