import 'dart:async';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_repository.dart';

/// Thursday, 22 October 2026, as in the design.
final DateTime calendarTestToday = DateTime(2026, 10, 22);

/// A day with one signed check-in, or no events on any other day.
CalendarDayEntity testCalendarDay(DateTime date) {
  final bool isToday = date == calendarTestToday;
  return CalendarDayEntity(
    date: date,
    today: calendarTestToday,
    events: <CalendarEventEntity>[
      if (isToday)
        CalendarEventEntity(
          id: 'e1',
          bookingId: 'b1',
          kind: CalendarEventKind.checkIn,
          at: DateTime(2026, 10, 22, 14),
          guestName: 'Айжан',
          propertyId: 'p1',
          propertyName: 'Esentai City',
          unit: '84',
          imageUrl: AppAssets.images.propertyLivingRoomWarm,
          nights: 3,
          isContractSigned: true,
        ),
    ],
    syncCheckedAt: DateTime(2026, 10, 22, 9, 38),
    isSyncHealthy: true,
  );
}

/// [CalendarRepository] that records requests and answers with
/// [testCalendarDay], or with [dayFailure] when it is set.
///
/// Set [holdDays] to keep the next requests pending; each gets a completer
/// in [heldDays].
final class FakeCalendarRepository implements CalendarRepository {
  Failure? dayFailure;

  bool holdDays = false;
  final List<Completer<Either<Failure, CalendarDayEntity>>> heldDays =
      <Completer<Either<Failure, CalendarDayEntity>>>[];

  final List<({DateTime? date, bool favoritesOnly})> requests =
      <({DateTime? date, bool favoritesOnly})>[];

  @override
  Future<Either<Failure, CalendarDayEntity>> getDay({
    required bool favoritesOnly,
    DateTime? date,
  }) async {
    requests.add((date: date, favoritesOnly: favoritesOnly));
    if (holdDays) {
      final Completer<Either<Failure, CalendarDayEntity>> completer =
          Completer<Either<Failure, CalendarDayEntity>>();
      heldDays.add(completer);
      return completer.future;
    }
    final Failure? failure = dayFailure;
    if (failure != null) {
      return Left<Failure, CalendarDayEntity>(failure);
    }
    return Right<Failure, CalendarDayEntity>(
      testCalendarDay(date ?? calendarTestToday),
    );
  }
}
