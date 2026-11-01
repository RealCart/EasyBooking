import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_day_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_bloc/calendar_bloc.dart';

import '../../../../../helpers/fake_calendar_repository.dart';

final class _Subject {
  _Subject() {
    bloc = CalendarBloc(getCalendarDay: GetCalendarDayUsecase(repository));
    final StreamSubscription<CalendarState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeCalendarRepository repository = FakeCalendarRepository();
  late final CalendarBloc bloc;
  final List<CalendarState> states = <CalendarState>[];

  Future<void> add(CalendarEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('CalendarBloc', () {
    test('the first load asks for today and learns its date', () async {
      final _Subject subject = _Subject();

      await subject.add(const CalendarRequested());

      expect(subject.repository.requests.single, (
        date: null,
        favoritesOnly: false,
      ));
      expect(subject.states, <CalendarState>[
        const CalendarState(loadStatus: RequestStatus.loading),
        CalendarState(
          loadStatus: RequestStatus.success,
          selectedDate: calendarTestToday,
          day: testCalendarDay(calendarTestToday),
        ),
      ]);
      expect(subject.bloc.state.selectedDay!.events, hasLength(1));
    });

    test('selecting a day loads it at midnight', () async {
      final _Subject subject = _Subject();
      await subject.add(const CalendarRequested());

      await subject.add(CalendarDaySelected(DateTime(2026, 10, 24, 15, 30)));

      expect(subject.repository.requests.last, (
        date: DateTime(2026, 10, 24),
        favoritesOnly: false,
      ));
      expect(subject.bloc.state.selectedDay!.date, DateTime(2026, 10, 24));
    });

    test('while a new day loads, the old day is not shown', () async {
      final _Subject subject = _Subject();
      await subject.add(const CalendarRequested());
      subject.repository.holdDays = true;

      await subject.add(CalendarDaySelected(DateTime(2026, 10, 24)));

      expect(subject.bloc.state.selectedDate, DateTime(2026, 10, 24));
      expect(subject.bloc.state.day!.date, calendarTestToday);
      expect(subject.bloc.state.selectedDay, isNull);
    });

    test('the favorites scope keeps the selected day', () async {
      final _Subject subject = _Subject();
      await subject.add(const CalendarRequested());
      await subject.add(CalendarDaySelected(DateTime(2026, 10, 24)));

      await subject.add(const CalendarScopeSelected(favoritesOnly: true));

      expect(subject.repository.requests.last, (
        date: DateTime(2026, 10, 24),
        favoritesOnly: true,
      ));
      expect(subject.bloc.state.favoritesOnly, isTrue);
    });

    test('the latest selection wins across event types', () async {
      final _Subject subject = _Subject();
      await subject.add(const CalendarRequested());
      subject.repository.holdDays = true;

      await subject.add(CalendarDaySelected(DateTime(2026, 10, 24)));
      await subject.add(const CalendarScopeSelected(favoritesOnly: true));
      subject.repository.heldDays[1].complete(
        Right<Failure, CalendarDayEntity>(
          testCalendarDay(DateTime(2026, 10, 24)),
        ),
      );
      await pumpEventQueue();
      subject.repository.heldDays[0].complete(
        Right<Failure, CalendarDayEntity>(testCalendarDay(calendarTestToday)),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.day!.date, DateTime(2026, 10, 24));
      expect(subject.bloc.state.favoritesOnly, isTrue);
    });

    test('a failure is reported and cleared by a retry', () async {
      final _Subject subject = _Subject();
      subject.repository.dayFailure = const ConnectionFailure();
      await subject.add(const CalendarRequested());
      expect(subject.bloc.state.loadFailure, const ConnectionFailure());

      subject.repository.dayFailure = null;
      await subject.add(const CalendarRequested());

      expect(subject.bloc.state.loadFailure, isNull);
      expect(subject.bloc.state.selectedDay, isNotNull);
    });
  });
}
