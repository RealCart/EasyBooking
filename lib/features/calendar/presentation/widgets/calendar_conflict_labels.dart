import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_labels.dart';

extension CalendarConflictLabels on CalendarConflictEntity {
  /// `1 из 1`
  String get positionLabel => '$position из $total';

  /// `Esentai City · квартира 84`
  String get propertyLabel => '$propertyName · квартира $unit';

  /// `24–25 октября пересекаются в двух источниках.`
  String get overlapLabel {
    final String sources = bookings.length == 2
        ? 'двух'
        : bookings.length.toString();
    return '${DateFormatter.dayRange(overlapStart, overlapEnd)} '
        'пересекаются в $sources источниках.';
  }

  /// The booking the host kept, once the conflict is resolved.
  ConflictBookingEntity? get keptBooking {
    for (final ConflictBookingEntity booking in bookings) {
      if (booking.bookingId == keptBookingId) {
        return booking;
      }
    }
    return null;
  }
}

extension ConflictBookingLabels on ConflictBookingEntity {
  /// `Airbnb · Айжан`
  String get title => '${source.title} · $guestName';

  /// `Подтверждена`, or `Создана вчера` for a booking not confirmed yet.
  String statusLabel({required DateTime now}) {
    if (isConfirmed) {
      return 'Подтверждена';
    }
    final String day = switch (now.dateOnly.nightsUntil(createdAt)) {
      0 => 'сегодня',
      -1 => 'вчера',
      _ => DateFormatter.dayMonth(createdAt),
    };
    return 'Создана $day';
  }

  /// `22–25 октября · 3 ночи`
  String get datesLabel {
    return '${DateFormatter.dayRange(checkIn, checkOut)} · '
        '${CalendarLabels.nights(nights)}';
  }

  /// `127 500 ₸ · код HM73P2`, or the phone check when there is no code.
  String get detailsLabel {
    final String price = MoneyFormatter.tenge(totalPrice);
    final String? code = confirmationCode;
    if (code != null) {
      return '$price · код $code';
    }
    return isPhoneVerified
        ? '$price · телефон подтверждён'
        : '$price · телефон не подтверждён';
  }

  /// `Оставить Airbnb`, `Оставить ручную`.
  String get keepLabel => 'Оставить ${source.keepTitle}';
}
