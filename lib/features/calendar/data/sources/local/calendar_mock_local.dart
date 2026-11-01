import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';

/// A sample week of check-ins and check-outs around today, until the
/// calendar API exists: every event of the bookings mock from two days ago
/// to five days ahead, with the same guests, apartments, and times, and the
/// contract state of the contracts mock. Property ids match the properties
/// mock.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Replace it with a `CalendarRemote`
/// returning models when the endpoint is ready.
abstract interface class CalendarMockLocal {
  /// The events of [date], or of today when it is `null`.
  Future<Either<Failure, CalendarDayEntity>> loadDay(DateTime? date);
}

final class CalendarMockLocalImpl implements CalendarMockLocal {
  /// [now] supplies the current time, so the week is around today.
  const CalendarMockLocalImpl({required this._now});

  final DateTime Function() _now;

  @override
  Future<Either<Failure, CalendarDayEntity>> loadDay(DateTime? date) async {
    final DateTime now = _now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = date == null
        ? today
        : DateTime(date.year, date.month, date.day);

    final List<CalendarEventEntity> events =
        <CalendarEventEntity>[
          for (final CalendarEventEntity event in _week(today))
            if (_isSameDay(event.at, day)) event,
        ]..sort(
          (CalendarEventEntity a, CalendarEventEntity b) =>
              a.at.compareTo(b.at),
        );

    return Right<Failure, CalendarDayEntity>(
      CalendarDayEntity(
        date: day,
        today: today,
        events: List<CalendarEventEntity>.unmodifiable(events),
        syncCheckedAt: now.subtract(const Duration(minutes: 3)),
        isSyncHealthy: true,
      ),
    );
  }

  List<CalendarEventEntity> _week(DateTime today) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(
        today.year,
        today.month,
        today.day + dayOffset,
        hour,
        minute,
      );
    }

    final String esentaiImage = AppAssets.images.propertyLivingRoomWarm;
    final String megaImage = AppAssets.images.propertyLivingRoomBlue;
    final String samalImage = AppAssets.images.propertyDiningRoom;
    final String highvillImage = AppAssets.images.propertyLivingRoomBlue;

    return <CalendarEventEntity>[
      CalendarEventEntity(
        id: 'in-1037',
        bookingId: 'booking-1037',
        kind: CalendarEventKind.checkIn,
        at: at(-2, 16),
        guestName: 'Асель',
        propertyId: 'samal-residence',
        propertyName: 'Samal Residence',
        unit: '7',
        imageUrl: samalImage,
        nights: 6,
        // Signed the day after check-in.
        isContractSigned: true,
      ),
      CalendarEventEntity(
        id: 'in-1039',
        bookingId: 'booking-1039',
        kind: CalendarEventKind.checkIn,
        at: at(-2, 15),
        guestName: 'Арман',
        propertyId: 'mega-towers-126',
        propertyName: 'Mega Towers',
        unit: '126',
        imageUrl: megaImage,
        nights: 2,
        isContractSigned: false,
      ),
      CalendarEventEntity(
        id: 'in-1034',
        bookingId: 'booking-1034',
        kind: CalendarEventKind.checkIn,
        at: at(-1, 15),
        guestName: 'Мадина',
        propertyId: 'highvill-5',
        propertyName: 'Highvill',
        unit: '5',
        imageUrl: highvillImage,
        nights: 3,
        isContractSigned: true,
      ),
      CalendarEventEntity(
        id: 'out-1039',
        bookingId: 'booking-1039',
        kind: CalendarEventKind.checkOut,
        at: at(0, 12),
        guestName: 'Арман',
        propertyId: 'mega-towers-126',
        propertyName: 'Mega Towers',
        unit: '126',
        imageUrl: megaImage,
        nights: 2,
        note: 'Ключи оставит в сейфе',
      ),
      CalendarEventEntity(
        id: 'in-1042',
        bookingId: 'booking-1042',
        kind: CalendarEventKind.checkIn,
        at: at(0, 14),
        guestName: 'Айжан',
        propertyId: 'esentai-city-84',
        propertyName: 'Esentai City',
        unit: '84',
        imageUrl: esentaiImage,
        nights: 3,
        isContractSigned: true,
      ),
      CalendarEventEntity(
        id: 'in-1044',
        bookingId: 'booking-1044',
        kind: CalendarEventKind.checkIn,
        at: at(0, 18, 30),
        guestName: 'Данияр',
        propertyId: 'samal-residence',
        propertyName: 'Samal Residence',
        unit: '12',
        imageUrl: samalImage,
        nights: 2,
        isContractSigned: false,
      ),
      CalendarEventEntity(
        id: 'out-1044',
        bookingId: 'booking-1044',
        kind: CalendarEventKind.checkOut,
        at: at(2, 12),
        guestName: 'Данияр',
        propertyId: 'samal-residence',
        propertyName: 'Samal Residence',
        unit: '12',
        imageUrl: samalImage,
        nights: 2,
        note: 'Уборка в 13:00',
      ),
      CalendarEventEntity(
        id: 'out-1034',
        bookingId: 'booking-1034',
        kind: CalendarEventKind.checkOut,
        at: at(2, 12),
        guestName: 'Мадина',
        propertyId: 'highvill-5',
        propertyName: 'Highvill',
        unit: '5',
        imageUrl: highvillImage,
        nights: 3,
      ),
      CalendarEventEntity(
        id: 'in-1046',
        bookingId: 'booking-1046',
        kind: CalendarEventKind.checkIn,
        at: at(2, 14),
        guestName: 'Марат',
        propertyId: 'esentai-city-84',
        propertyName: 'Esentai City',
        unit: '84',
        imageUrl: esentaiImage,
        nights: 3,
        isContractSigned: false,
      ),
      CalendarEventEntity(
        id: 'out-1042',
        bookingId: 'booking-1042',
        kind: CalendarEventKind.checkOut,
        at: at(3, 12),
        guestName: 'Айжан',
        propertyId: 'esentai-city-84',
        propertyName: 'Esentai City',
        unit: '84',
        imageUrl: esentaiImage,
        nights: 3,
        note: 'Уборка назначена',
      ),
      CalendarEventEntity(
        id: 'in-1047',
        bookingId: 'booking-1047',
        kind: CalendarEventKind.checkIn,
        at: at(3, 14),
        guestName: 'Олег',
        propertyId: 'esentai-city-84',
        propertyName: 'Esentai City',
        unit: '84',
        imageUrl: esentaiImage,
        nights: 3,
        isContractSigned: false,
      ),
      CalendarEventEntity(
        id: 'in-1051',
        bookingId: 'booking-1051',
        kind: CalendarEventKind.checkIn,
        at: at(3, 15),
        guestName: 'Тимур',
        propertyId: 'mega-towers-126',
        propertyName: 'Mega Towers',
        unit: '126',
        imageUrl: megaImage,
        nights: 2,
        isContractSigned: true,
      ),
      CalendarEventEntity(
        id: 'out-1037',
        bookingId: 'booking-1037',
        kind: CalendarEventKind.checkOut,
        at: at(4, 12),
        guestName: 'Асель',
        propertyId: 'samal-residence',
        propertyName: 'Samal Residence',
        unit: '7',
        imageUrl: samalImage,
        nights: 6,
      ),
      CalendarEventEntity(
        id: 'out-1046',
        bookingId: 'booking-1046',
        kind: CalendarEventKind.checkOut,
        at: at(5, 12),
        guestName: 'Марат',
        propertyId: 'esentai-city-84',
        propertyName: 'Esentai City',
        unit: '84',
        imageUrl: esentaiImage,
        nights: 3,
      ),
      CalendarEventEntity(
        id: 'out-1051',
        bookingId: 'booking-1051',
        kind: CalendarEventKind.checkOut,
        at: at(5, 12),
        guestName: 'Тимур',
        propertyId: 'mega-towers-126',
        propertyName: 'Mega Towers',
        unit: '126',
        imageUrl: megaImage,
        nights: 2,
        note: 'Ключи у консьержа',
      ),
    ];
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
