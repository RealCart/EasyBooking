import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/occupancy_bloc/occupancy_bloc.dart';

import '../../../../../helpers/fake_occupancy_repository.dart';

final DateTime _nextWeek = DateTime(2026, 10, 26);
final DateTime _previousWeek = DateTime(2026, 10, 12);

final class _Subject {
  _Subject() {
    bloc = OccupancyBloc(getOccupancyWeek: GetOccupancyWeekUsecase(repository));
    final StreamSubscription<OccupancyState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeOccupancyRepository repository = FakeOccupancyRepository();
  late final OccupancyBloc bloc;
  final List<OccupancyState> states = <OccupancyState>[];

  Future<void> add(OccupancyEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> complete(int index, DateTime weekStart) async {
    repository.heldWeeks[index].complete(
      Right<Failure, OccupancyWeekEntity>(testOccupancyWeek(weekStart)),
    );
    await pumpEventQueue();
  }
}

void main() {
  group('OccupancyBloc', () {
    test('starts with nothing loaded', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const OccupancyState());
      expect(subject.bloc.state.selectedWeek, isNull);
    });

    test('the first load asks for the current week and learns it', () async {
      final _Subject subject = _Subject();

      await subject.add(const OccupancyRequested());

      expect(subject.repository.requests.single, (
        date: null,
        favoritesOnly: false,
      ));
      expect(subject.states, <OccupancyState>[
        const OccupancyState(loadStatus: RequestStatus.loading),
        OccupancyState(
          loadStatus: RequestStatus.success,
          weekStart: occupancyTestWeekStart,
          week: testOccupancyWeek(occupancyTestWeekStart),
        ),
      ]);
      expect(
        subject.bloc.state.selectedWeek,
        testOccupancyWeek(occupancyTestWeekStart),
      );
    });

    test('selecting any day loads its week from Monday', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());

      await subject.add(OccupancyWeekSelected(DateTime(2026, 10, 29, 15, 30)));

      expect(subject.repository.requests.last, (
        date: _nextWeek,
        favoritesOnly: false,
      ));
      expect(subject.states[2].weekStart, _nextWeek);
      expect(subject.states[2].loadStatus, RequestStatus.loading);
      expect(subject.bloc.state.selectedWeek!.weekStart, _nextWeek);
    });

    test('while another week loads, the old week is not selected', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      subject.repository.holdWeeks = true;

      await subject.add(OccupancyWeekSelected(_nextWeek));

      expect(subject.bloc.state.weekStart, _nextWeek);
      expect(subject.bloc.state.week!.weekStart, occupancyTestWeekStart);
      expect(subject.bloc.state.selectedWeek, isNull);
    });

    test('«Сегодня» clears the week while it loads the current one', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      await subject.add(OccupancyWeekSelected(_nextWeek));
      subject.repository.holdWeeks = true;

      await subject.add(const OccupancyCurrentWeekSelected());

      expect(subject.repository.requests.last, (
        date: null,
        favoritesOnly: false,
      ));
      expect(subject.bloc.state.weekStart, isNull);
      expect(subject.bloc.state.selectedWeek, isNull);

      await subject.complete(0, occupancyTestWeekStart);

      expect(subject.bloc.state.weekStart, occupancyTestWeekStart);
      expect(subject.bloc.state.selectedWeek, isNotNull);
    });

    test('the scope keeps the selected week', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      await subject.add(OccupancyWeekSelected(_nextWeek));

      await subject.add(const OccupancyScopeSelected(favoritesOnly: true));

      expect(subject.repository.requests.last, (
        date: _nextWeek,
        favoritesOnly: true,
      ));
      expect(subject.bloc.state.favoritesOnly, isTrue);
      expect(subject.bloc.state.weekStart, _nextWeek);
    });

    test('a retry keeps the scope and the week', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyScopeSelected(favoritesOnly: true));
      await subject.add(OccupancyWeekSelected(_previousWeek));

      await subject.add(const OccupancyRequested());

      expect(subject.repository.requests.last, (
        date: _previousWeek,
        favoritesOnly: true,
      ));
    });

    test('a stale week does not replace a newer one', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      subject.repository.holdWeeks = true;
      await subject.add(OccupancyWeekSelected(_nextWeek));
      await subject.add(OccupancyWeekSelected(_previousWeek));
      final int statesBefore = subject.states.length;

      await subject.complete(1, _previousWeek);
      await subject.complete(0, _nextWeek);

      expect(subject.bloc.state.weekStart, _previousWeek);
      expect(subject.bloc.state.selectedWeek!.weekStart, _previousWeek);
      expect(subject.states.length, statesBefore + 1);
      expect(
        subject.states.map((OccupancyState s) => s.week?.weekStart),
        isNot(contains(_nextWeek)),
      );
    });

    test('the latest event wins across event types', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      subject.repository.holdWeeks = true;
      await subject.add(OccupancyWeekSelected(_nextWeek));
      await subject.add(const OccupancyCurrentWeekSelected());

      await subject.complete(1, occupancyTestWeekStart);
      await subject.complete(0, _nextWeek);

      expect(subject.bloc.state.weekStart, occupancyTestWeekStart);
      expect(subject.bloc.state.week!.weekStart, occupancyTestWeekStart);
    });

    test('a failure is reported, then cleared by a retry', () async {
      final _Subject subject = _Subject();
      subject.repository.weekFailure = const ConnectionFailure();

      await subject.add(const OccupancyRequested());

      expect(subject.states.last.loadStatus, RequestStatus.failure);
      expect(subject.states.last.loadFailure, const ConnectionFailure());

      subject.repository.weekFailure = null;
      await subject.add(const OccupancyRequested());

      final OccupancyState retrying = subject.states[2];
      expect(retrying.loadStatus, RequestStatus.loading);
      expect(retrying.loadFailure, isNull);
      expect(subject.bloc.state.loadFailure, isNull);
      expect(subject.bloc.state.selectedWeek, isNotNull);
    });

    test('a failed reload keeps the last week but selects none', () async {
      final _Subject subject = _Subject();
      await subject.add(const OccupancyRequested());
      subject.repository.weekFailure = const TimeoutFailure();

      await subject.add(OccupancyWeekSelected(_nextWeek));

      expect(subject.bloc.state.week!.weekStart, occupancyTestWeekStart);
      expect(subject.bloc.state.loadFailure, const TimeoutFailure());
      expect(subject.bloc.state.selectedWeek, isNull);
    });

    test('a week arriving after close is dropped without errors', () async {
      final _Subject subject = _Subject();
      subject.repository.holdWeeks = true;
      await subject.add(const OccupancyRequested());
      final int statesBefore = subject.states.length;

      await subject.bloc.close();
      await subject.complete(0, occupancyTestWeekStart);

      expect(subject.bloc.isClosed, isTrue);
      expect(subject.states.length, statesBefore);
      expect(subject.bloc.state.loadStatus, RequestStatus.loading);
    });
  });
}
