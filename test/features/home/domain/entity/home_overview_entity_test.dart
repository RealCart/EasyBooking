import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';

import '../../../../helpers/fake_home_repository.dart';

HomeStayEntity _stay(DateTime checkIn, DateTime checkOut) {
  return HomeStayEntity(
    propertyId: 'p1',
    propertyName: 'Esentai City',
    guestName: 'Айжан',
    checkIn: checkIn,
    checkOut: checkOut,
    status: HomeStayStatus.ready,
  );
}

void main() {
  group('HomeStayEntity.nights', () {
    test('counts calendar days regardless of the times', () {
      expect(
        _stay(DateTime(2026, 10, 22, 23), DateTime(2026, 10, 25, 1)).nights,
        3,
      );
    });

    test('spans a month boundary', () {
      expect(
        _stay(DateTime(2026, 10, 30, 14), DateTime(2026, 11, 2, 12)).nights,
        3,
      );
    });
  });

  group('HomeOverviewEntity.staysFor', () {
    test('returns the list of each scope', () {
      final HomeOverviewEntity overview = testHomeOverview();

      expect(overview.staysFor(HomeStayScope.arrivals), overview.arrivals);
      expect(overview.staysFor(HomeStayScope.departures), overview.departures);
      expect(overview.staysFor(HomeStayScope.staying), overview.staying);
    });
  });
}
