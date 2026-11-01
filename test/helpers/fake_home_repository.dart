import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/domain/entity/calendar_sync_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_task_entity.dart';
import 'package:easy_booking/features/home/domain/repository/home_repository.dart';

/// A small overview for tests: one arrival, no departures or current
/// guests, one contract task. [propertyName] tells overviews apart.
HomeOverviewEntity testHomeOverview({String propertyName = 'Esentai City'}) {
  return HomeOverviewEntity(
    date: DateTime(2026, 10, 22),
    arrivals: <HomeStayEntity>[
      HomeStayEntity(
        propertyId: 'p1',
        propertyName: propertyName,
        guestName: 'Айжан',
        checkIn: DateTime(2026, 10, 22, 14),
        checkOut: DateTime(2026, 10, 25, 12),
        status: HomeStayStatus.ready,
      ),
    ],
    departures: const <HomeStayEntity>[],
    staying: const <HomeStayEntity>[],
    tasks: const <HomeTaskEntity>[
      HomeTaskEntity(
        kind: HomeTaskKind.contract,
        targetId: 'c1',
        title: 'Договор Данияра',
        subtitle: 'Samal · ещё не подписан',
      ),
    ],
    sync: CalendarSyncEntity(
      updatedAt: DateTime(2026, 10, 22, 9, 38),
      channelNames: const <String>['Airbnb'],
      propertyCount: 1,
    ),
  );
}

/// [HomeRepository] that answers with [overviewResult].
///
/// Set [holdOverview] to keep the next calls pending; each pending call gets
/// a completer in [heldOverviews], which the test completes in any order.
final class FakeHomeRepository implements HomeRepository {
  Either<Failure, HomeOverviewEntity> overviewResult =
      Right<Failure, HomeOverviewEntity>(testHomeOverview());

  bool holdOverview = false;

  final List<Completer<Either<Failure, HomeOverviewEntity>>> heldOverviews =
      <Completer<Either<Failure, HomeOverviewEntity>>>[];

  int overviewCount = 0;

  @override
  Future<Either<Failure, HomeOverviewEntity>> getOverview() async {
    overviewCount += 1;
    if (!holdOverview) {
      return overviewResult;
    }
    final Completer<Either<Failure, HomeOverviewEntity>> completer =
        Completer<Either<Failure, HomeOverviewEntity>>();
    heldOverviews.add(completer);
    return completer.future;
  }
}
