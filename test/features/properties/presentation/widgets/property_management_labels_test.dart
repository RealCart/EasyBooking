import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_management_labels.dart';

PropertyBookingEntity _booking(
  PropertyBookingStatus status, {
  BookingChannel? channel = BookingChannel.airbnb,
}) {
  return PropertyBookingEntity(
    id: 'b',
    guestName: 'Гость',
    checkIn: DateTime(2026, 10, 22, 14),
    checkOut: DateTime(2026, 10, 25, 12),
    guestCount: 2,
    channel: channel,
    status: status,
    totalPrice: 127500,
    hasContract: true,
  );
}

void main() {
  group('PropertyBookingLabels.statusLabel', () {
    final Map<PropertyBookingStatus, String> labels =
        <PropertyBookingStatus, String>{
          PropertyBookingStatus.confirmed: 'Подтверждено',
          PropertyBookingStatus.paid: 'Оплачено',
          PropertyBookingStatus.staying: 'Живёт',
          PropertyBookingStatus.pending: 'Ожидает',
          PropertyBookingStatus.completed: 'Завершено',
          PropertyBookingStatus.cancelled: 'Отменено',
        };
    for (final MapEntry<PropertyBookingStatus, String> entry
        in labels.entries) {
      test('${entry.key.name} from a channel is «${entry.value}»', () {
        expect(_booking(entry.key).statusLabel, entry.value);
      });
    }

    test('a pending direct booking is «Напрямую»', () {
      expect(
        _booking(PropertyBookingStatus.pending, channel: null).statusLabel,
        'Напрямую',
      );
    });
  });

  group('booking dates and price', () {
    test('a channel booking names the channel and the nights', () {
      final PropertyBookingEntity booking = _booking(
        PropertyBookingStatus.paid,
      );

      expect(booking.datesLabel, '22–25 октября · Airbnb');
      expect(booking.priceLabel, startsWith('3 ночи · '));
    });

    test('a direct booking shows the nights in the dates', () {
      final PropertyBookingEntity booking = _booking(
        PropertyBookingStatus.pending,
        channel: null,
      );

      expect(booking.datesLabel, '22–25 октября · 3 ночи');
      expect(booking.priceLabel, isNot(contains('ночи')));
    });
  });

  group('timeOfDayLabel', () {
    test('pads hours and minutes', () {
      expect(timeOfDayLabel(const Duration(hours: 9, minutes: 5)), '09:05');
      expect(timeOfDayLabel(const Duration(hours: 14)), '14:00');
    });
  });

  group('bookingMonthLabel', () {
    test('omits the year of the current year only', () {
      final DateTime now = DateTime(2026, 10, 22);

      expect(bookingMonthLabel(DateTime(2026, 11, 3), now: now), 'НОЯБРЬ');
      expect(
        bookingMonthLabel(DateTime(2027, 1, 5), now: now),
        'ЯНВАРЬ 2027',
      );
    });
  });

  group('field and failure messages', () {
    test('field codes map to texts and no code to null', () {
      expect(propertyFieldErrorMessage(null), isNull);
      expect(propertyFieldErrorMessage(''), isNull);
      expect(
        propertyFieldErrorMessage(PropertyErrorCodes.required),
        FormValidators.requiredMessage,
      );
      expect(
        propertyFieldErrorMessage(PropertyErrorCodes.outOfRange),
        'Значение вне допустимых пределов',
      );
    });

    test('draftIncomplete has its own message, others the shared one', () {
      expect(
        const ValidationFailure(
          code: PropertyErrorCodes.draftIncomplete,
        ).propertyMessage,
        'Сначала заполните название и адрес квартиры',
      );
      expect(
        const ConnectionFailure().propertyMessage,
        const ConnectionFailure().userMessage,
      );
    });
  });
}
