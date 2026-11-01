import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/domain/entity/calendar_sync_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_task_entity.dart';

/// Sample data for the home screen until the home API exists. Stays,
/// property ids, and the contract task match the bookings, properties, and
/// contracts mocks.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Replace it with a `HomeRemote` returning
/// models when the endpoint is ready.
abstract interface class HomeMockLocal {
  Future<Either<Failure, HomeOverviewEntity>> loadOverview();
}

final class HomeMockLocalImpl implements HomeMockLocal {
  /// [now] supplies the current time, so the sample day is always today.
  const HomeMockLocalImpl({required this._now});

  final DateTime Function() _now;

  @override
  Future<Either<Failure, HomeOverviewEntity>> loadOverview() async {
    final DateTime now = _now();

    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    return Right<Failure, HomeOverviewEntity>(
      HomeOverviewEntity(
        date: DateTime(now.year, now.month, now.day),
        // Today's stays of the bookings mock: arrivals 1042 and 1044, the
        // departure 1039, and the current stays 1037 and 1034.
        arrivals: <HomeStayEntity>[
          HomeStayEntity(
            propertyId: 'esentai-city-84',
            propertyName: 'Esentai City · 84',
            imageUrl: AppAssets.images.propertyLivingRoomWarm,
            guestName: 'Айжан',
            checkIn: at(0, 14),
            checkOut: at(3, 12),
            status: HomeStayStatus.ready,
          ),
          HomeStayEntity(
            propertyId: 'samal-residence',
            propertyName: 'Samal Residence · 12',
            imageUrl: AppAssets.images.propertyDiningRoom,
            guestName: 'Данияр',
            checkIn: at(0, 18, 30),
            checkOut: at(2, 12),
            status: HomeStayStatus.awaitingContract,
          ),
        ],
        departures: <HomeStayEntity>[
          HomeStayEntity(
            propertyId: 'mega-towers-126',
            propertyName: 'Mega Towers · 126',
            imageUrl: AppAssets.images.propertyLivingRoomBlue,
            guestName: 'Арман',
            checkIn: at(-2, 15),
            checkOut: at(0, 12),
            status: HomeStayStatus.cleaningScheduled,
          ),
        ],
        staying: <HomeStayEntity>[
          HomeStayEntity(
            propertyId: 'highvill-5',
            propertyName: 'Highvill · 5',
            imageUrl: AppAssets.images.propertyLivingRoomBlue,
            guestName: 'Мадина',
            checkIn: at(-1, 15),
            checkOut: at(2, 12),
            status: HomeStayStatus.contractSigned,
          ),
          // Apartment 7 of Samal Residence has no property of its own.
          HomeStayEntity(
            propertyId: 'samal-residence',
            propertyName: 'Samal Residence · 7',
            imageUrl: AppAssets.images.propertyDiningRoom,
            guestName: 'Асель',
            checkIn: at(-2, 16),
            checkOut: at(4, 12),
            status: HomeStayStatus.contractSigned,
          ),
        ],
        tasks: <HomeTaskEntity>[
          const HomeTaskEntity(
            kind: HomeTaskKind.contract,
            targetId: 'eb-1052',
            title: 'Договор Данияра',
            subtitle: 'Samal · ещё не подписан',
          ),
          HomeTaskEntity(
            kind: HomeTaskKind.preparation,
            targetId: 'esentai-city-84',
            title: 'Подготовить квартиру',
            subtitle: 'Esentai · уборка, Алия',
            dueAt: at(0, 13),
          ),
        ],
        sync: CalendarSyncEntity(
          updatedAt: at(0, 9, 38),
          channelNames: const <String>['Booking.com', 'Airbnb'],
          propertyCount: 4,
        ),
      ),
    );
  }
}
