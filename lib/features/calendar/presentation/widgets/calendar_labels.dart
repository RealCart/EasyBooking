import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';

extension CalendarEventLabels on CalendarEventEntity {
  /// `Заезд · Айжан`
  String get title {
    final String action = switch (kind) {
      CalendarEventKind.checkIn => 'Заезд',
      CalendarEventKind.checkOut => 'Выезд',
    };
    return '$action · $guestName';
  }

  /// `Esentai City · квартира 84`
  String get propertyLabel => '$propertyName · квартира $unit';

  /// `3 ночи · договор подписан` for an arrival; the note for a departure.
  String get details {
    if (kind == CalendarEventKind.checkOut) {
      return note ?? 'Выезд по брони';
    }
    final String nightsLabel = Plural.format(
      nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );
    final String? contract = switch (isContractSigned) {
      true => 'договор подписан',
      false => 'ждём подпись',
      null => null,
    };
    return contract == null ? nightsLabel : '$nightsLabel · $contract';
  }
}

extension CalendarDayLabels on CalendarDayEntity {
  String get syncTitle {
    return isSyncHealthy
        ? 'Все календари обновлены'
        : 'Не все календари обновились';
  }

  /// `Последняя проверка сегодня, 09:38`
  String get syncSubtitle {
    return 'Последняя проверка '
        '${DateFormatter.relativeDayTime(syncCheckedAt, now: today)}';
  }
}

extension BookingSourceLabels on BookingSource {
  /// `Airbnb`, `Booking.com`, `Ручная`: the source of a booking in a list.
  String get title => switch (this) {
    BookingSource.airbnb => 'Airbnb',
    BookingSource.bookingCom => 'Booking.com',
    BookingSource.direct => 'Ручная',
  };

  /// `Airbnb`, `Booking`, `напрямую`: the source on a narrow occupancy bar.
  String get shortTitle => switch (this) {
    BookingSource.airbnb => 'Airbnb',
    BookingSource.bookingCom => 'Booking',
    BookingSource.direct => 'напрямую',
  };

  /// `Airbnb`, `Booking.com`, `ручную`: the object of «Оставить …».
  String get keepTitle => switch (this) {
    BookingSource.airbnb => 'Airbnb',
    BookingSource.bookingCom => 'Booking.com',
    BookingSource.direct => 'ручную',
  };
}

abstract final class CalendarLabels {
  /// `3 ночи`
  static String nights(int count) {
    return Plural.format(count, one: 'ночь', few: 'ночи', many: 'ночей');
  }

  /// `4 объекта`
  static String properties(int count) {
    return Plural.format(
      count,
      one: 'объект',
      few: 'объекта',
      many: 'объектов',
    );
  }

  /// `09:38` for a time of [now]'s day, otherwise `вчера, 18:10` or
  /// `22 октября, 09:38`.
  static String checkTime(DateTime at, {required DateTime now}) {
    return at.isSameDay(now)
        ? DateFormatter.time(at)
        : DateFormatter.relativeDayTime(at, now: now);
  }

  /// `сегодня в 09:38`, `вчера в 18:10`, `22 октября в 09:38`.
  static String dayAtTime(DateTime at, {required DateTime now}) {
    final int days = now.dateOnly.nightsUntil(at);
    final String day = switch (days) {
      0 => 'сегодня',
      -1 => 'вчера',
      1 => 'завтра',
      _ => DateFormatter.dayMonth(at),
    };
    return '$day в ${DateFormatter.time(at)}';
  }
}
