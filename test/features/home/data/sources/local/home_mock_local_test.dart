import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/data/sources/local/home_mock_local.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';

void main() {
  group('HomeMockLocalImpl', () {
    final DateTime now = DateTime(2026, 10, 22, 8, 15);

    Future<HomeOverviewEntity> load() async {
      final Either<Failure, HomeOverviewEntity> result =
          await HomeMockLocalImpl(now: () => now).loadOverview();
      return switch (result) {
        Right<Failure, HomeOverviewEntity>(:final HomeOverviewEntity value) =>
          value,
        Left<Failure, HomeOverviewEntity>(:final Failure value) => fail(
          'Unexpected failure $value',
        ),
      };
    }

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    test('the overview is for the day of the clock', () async {
      final HomeOverviewEntity overview = await load();

      expect(overview.date, DateTime(2026, 10, 22));
    });

    test('arrivals check in and departures check out on that day', () async {
      final HomeOverviewEntity overview = await load();

      expect(overview.arrivals, hasLength(2));
      expect(overview.departures, hasLength(1));
      expect(overview.staying, hasLength(3));
      for (final HomeStayEntity stay in overview.arrivals) {
        expect(isSameDay(stay.checkIn, now), isTrue);
      }
      for (final HomeStayEntity stay in overview.departures) {
        expect(isSameDay(stay.checkOut, now), isTrue);
      }
    });

    test('current guests neither arrive nor leave on that day', () async {
      final HomeOverviewEntity overview = await load();

      for (final HomeStayEntity stay in overview.staying) {
        expect(stay.checkIn.isBefore(now), isTrue);
        expect(isSameDay(stay.checkOut, now), isFalse);
        expect(stay.checkOut.isAfter(now), isTrue);
      }
    });

    test('the sync time is on that day', () async {
      final HomeOverviewEntity overview = await load();

      expect(overview.sync.updatedAt, DateTime(2026, 10, 22, 9, 38));
      expect(overview.sync.channelNames, <String>['Booking.com', 'Airbnb']);
    });

    test('a clock at month end rolls the stays into the next month', () async {
      final HomeOverviewEntity overview =
          await HomeMockLocalImpl(now: () => DateTime(2026, 10, 31, 8))
              .loadOverview()
              .then(
                (Either<Failure, HomeOverviewEntity> result) => result.fold(
                  (Failure failure) => fail('Unexpected failure $failure'),
                  (HomeOverviewEntity overview) => overview,
                ),
              );

      expect(overview.arrivals.first.checkOut, DateTime(2026, 11, 3, 12));
      expect(overview.arrivals.first.nights, 3);
    });
  });
}
