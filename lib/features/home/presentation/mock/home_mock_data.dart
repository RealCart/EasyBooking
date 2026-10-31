import 'package:easy_booking/app/constants/assets/app_assets.dart';

// Temporary data for the home screen. Replace it with domain entities and a
// BLoC when the home domain and data layers are implemented.

/// The stays shown by the scope filter of the home screen.
enum HomeStayScope { arrivals, departures, staying }

enum HomeStayStatus {
  ready,
  awaitingContract,
  cleaningScheduled,
  contractSigned,
}

enum HomeTaskKind { contract, preparation }

final class HomeStayMock {
  const HomeStayMock({
    required this.propertyId,
    required this.propertyName,
    required this.imagePath,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  final String propertyId;
  final String propertyName;
  final String imagePath;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final HomeStayStatus status;

  /// Calendar nights, so a DST change does not shift the count.
  int get nights {
    final DateTime start = DateTime.utc(
      checkIn.year,
      checkIn.month,
      checkIn.day,
    );
    final DateTime end = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );
    return end.difference(start).inDays;
  }
}

final class HomeTaskMock {
  const HomeTaskMock({
    required this.kind,
    required this.targetId,
    required this.title,
    required this.subtitle,
    this.dueAt,
  });

  final HomeTaskKind kind;

  /// Contract id for [HomeTaskKind.contract], property id otherwise.
  final String targetId;
  final String title;
  final String subtitle;
  final DateTime? dueAt;
}

final class HomeSyncMock {
  const HomeSyncMock({
    required this.updatedAt,
    required this.channelNames,
    required this.propertyCount,
  });

  final DateTime updatedAt;
  final List<String> channelNames;
  final int propertyCount;
}

final class HomeMockData {
  const HomeMockData({
    required this.date,
    required this.arrivals,
    required this.departures,
    required this.staying,
    required this.tasks,
    required this.sync,
  });

  /// Builds the sample day around [today], so times stay on the current
  /// date.
  factory HomeMockData.forDay(DateTime today) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(
        today.year,
        today.month,
        today.day + dayOffset,
      ).add(Duration(hours: hour, minutes: minute));
    }

    return HomeMockData(
      date: today,
      arrivals: <HomeStayMock>[
        HomeStayMock(
          propertyId: 'esentai-city-84',
          propertyName: 'Esentai City · 84',
          imagePath: AppAssets.images.propertyLivingRoomWarm,
          guestName: 'Айжан',
          checkIn: at(0, 14),
          checkOut: at(3, 12),
          status: HomeStayStatus.ready,
        ),
        HomeStayMock(
          propertyId: 'samal-residence',
          propertyName: 'Samal Residence',
          imagePath: AppAssets.images.propertyDiningRoom,
          guestName: 'Данияр',
          checkIn: at(0, 18, 30),
          checkOut: at(2, 12),
          status: HomeStayStatus.awaitingContract,
        ),
      ],
      departures: <HomeStayMock>[
        HomeStayMock(
          propertyId: 'nurly-tau-12',
          propertyName: 'Nurly Tau · 12',
          imagePath: AppAssets.images.propertyLivingRoomBlue,
          guestName: 'Ерлан',
          checkIn: at(-2, 15),
          checkOut: at(0, 12),
          status: HomeStayStatus.cleaningScheduled,
        ),
      ],
      staying: <HomeStayMock>[
        HomeStayMock(
          propertyId: 'highvill-5',
          propertyName: 'Highvill · 5',
          imagePath: AppAssets.images.propertyLivingRoomBlue,
          guestName: 'Мадина',
          checkIn: at(-1, 14),
          checkOut: at(2, 12),
          status: HomeStayStatus.contractSigned,
        ),
        HomeStayMock(
          propertyId: 'esentai-city-12',
          propertyName: 'Esentai City · 12',
          imagePath: AppAssets.images.propertyLivingRoomWarm,
          guestName: 'Тимур',
          checkIn: at(-3, 14),
          checkOut: at(1, 12),
          status: HomeStayStatus.contractSigned,
        ),
        HomeStayMock(
          propertyId: 'samal-residence-7',
          propertyName: 'Samal Residence · 7',
          imagePath: AppAssets.images.propertyDiningRoom,
          guestName: 'Асель',
          checkIn: at(-2, 16),
          checkOut: at(4, 12),
          status: HomeStayStatus.awaitingContract,
        ),
      ],
      tasks: <HomeTaskMock>[
        const HomeTaskMock(
          kind: HomeTaskKind.contract,
          targetId: 'samal-daniyar',
          title: 'Договор Данияра',
          subtitle: 'Samal · ещё не подписан',
        ),
        HomeTaskMock(
          kind: HomeTaskKind.preparation,
          targetId: 'esentai-city-84',
          title: 'Подготовить квартиру',
          subtitle: 'Esentai · уборка, Алия',
          dueAt: at(0, 13),
        ),
      ],
      sync: HomeSyncMock(
        updatedAt: at(0, 9, 38),
        channelNames: const <String>['Booking.com', 'Airbnb'],
        propertyCount: 4,
      ),
    );
  }

  final DateTime date;
  final List<HomeStayMock> arrivals;
  final List<HomeStayMock> departures;
  final List<HomeStayMock> staying;
  final List<HomeTaskMock> tasks;
  final HomeSyncMock sync;

  List<HomeStayMock> staysFor(HomeStayScope scope) {
    return switch (scope) {
      HomeStayScope.arrivals => arrivals,
      HomeStayScope.departures => departures,
      HomeStayScope.staying => staying,
    };
  }
}
