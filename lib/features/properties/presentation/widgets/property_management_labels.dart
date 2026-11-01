import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';

/// `3 ночи`
String nightsLabel(int nights) {
  return Plural.format(nights, one: 'ночь', few: 'ночи', many: 'ночей');
}

/// `14:00` for a time since midnight.
String timeOfDayLabel(Duration time) {
  final int hours = time.inHours.remainder(Duration.hoursPerDay);
  final int minutes = time.inMinutes.remainder(Duration.minutesPerHour);
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

/// The group header of a booking list: `ОКТЯБРЬ`, or `ЯНВАРЬ 2027` for a
/// month of another year than [now].
String bookingMonthLabel(DateTime month, {required DateTime now}) {
  final String monthYear = DateFormatter.monthYear(month);
  final String label = month.year == now.year
      ? monthYear.substring(0, monthYear.lastIndexOf(' '))
      : monthYear;
  return label.toUpperCase();
}

extension PropertyTypeLabels on PropertyType {
  String get label {
    return switch (this) {
      PropertyType.apartment => 'Квартира',
      PropertyType.house => 'Дом',
      PropertyType.room => 'Комната',
    };
  }
}

extension BookingChannelLabels on BookingChannel {
  /// What connecting the channel gives, on «Подключите площадки».
  String get connectDescription {
    return switch (this) {
      BookingChannel.bookingCom => 'Ссылка на календарь iCal',
      BookingChannel.airbnb => 'Импорт занятости по ссылке',
      BookingChannel.krisha => 'Ручные брони и доступный экспорт',
    };
  }

  /// The action of a channel that is not connected yet.
  String get connectActionLabel {
    return switch (this) {
      BookingChannel.krisha => 'Настроить',
      BookingChannel.bookingCom || BookingChannel.airbnb => 'Подключить',
    };
  }

  /// The colour of the bar next to a booking from this channel.
  Color get accentColor {
    return switch (this) {
      BookingChannel.airbnb => AppColors.accent,
      BookingChannel.bookingCom => AppColors.info,
      BookingChannel.krisha => AppColors.success,
    };
  }
}

extension PropertyBookingLabels on PropertyBookingEntity {
  /// `Живёт`, `Подтверждено`, `Напрямую`.
  String get statusLabel {
    return switch (status) {
      PropertyBookingStatus.pending when isDirect => 'Напрямую',
      PropertyBookingStatus.pending => 'Ожидает',
      PropertyBookingStatus.confirmed => 'Подтверждено',
      PropertyBookingStatus.paid => 'Оплачено',
      PropertyBookingStatus.staying => 'Живёт',
      PropertyBookingStatus.completed => 'Завершено',
      PropertyBookingStatus.cancelled => 'Отменено',
    };
  }

  Color get statusColor {
    return switch (status) {
      PropertyBookingStatus.pending when isDirect => AppColors.secondaryText,
      PropertyBookingStatus.pending => AppColors.warning,
      PropertyBookingStatus.confirmed => AppColors.info,
      PropertyBookingStatus.paid ||
      PropertyBookingStatus.staying => AppColors.success,
      PropertyBookingStatus.completed => AppColors.secondaryText,
      PropertyBookingStatus.cancelled => AppColors.error,
    };
  }

  /// The bar colour: the channel's, or the text colour for a direct booking.
  Color get accentColor => channel?.accentColor ?? AppColors.text;

  /// `22–25 октября · Airbnb`, or `28–31 октября · 3 ночи` for a direct
  /// booking.
  String get datesLabel {
    final String dates = DateFormatter.dayRange(checkIn, checkOut);
    return '$dates · ${channel?.title ?? nightsLabel(nights)}';
  }

  /// `3 ночи · 127 500 ₸`; for a direct booking only the price, since the
  /// nights are already in [datesLabel].
  String get priceLabel {
    final String price = MoneyFormatter.tenge(totalPrice);
    return isDirect ? price : '${nightsLabel(nights)} · $price';
  }
}

extension PropertyTermsLabels on PropertyTermsEntity {
  /// `42 500 ₸ · депозит 50 000 ₸`
  String get priceAndDeposit {
    final String price = MoneyFormatter.tenge(pricePerNight);
    final String deposit = this.deposit == 0
        ? 'без депозита'
        : 'депозит ${MoneyFormatter.tenge(this.deposit)}';
    return '$price · $deposit';
  }

  /// `Заезд 14:00 · выезд 12:00`
  String get checkInOut {
    return 'Заезд ${timeOfDayLabel(checkInTime)} · '
        'выезд ${timeOfDayLabel(checkOutTime)}';
  }
}

/// Text for an `AddPropertyState.fieldErrors` value, or `null` when the field
/// has no error.
String? propertyFieldErrorMessage(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  return switch (code) {
    PropertyErrorCodes.required => FormValidators.requiredMessage,
    PropertyErrorCodes.outOfRange => 'Значение вне допустимых пределов',
    _ => 'Проверьте поле',
  };
}

extension PropertyFailureMessage on Failure {
  /// Text for a failure of the properties feature; known codes get their own
  /// message, anything else the shared [userMessage].
  String get propertyMessage {
    if (this case ValidationFailure(code: PropertyErrorCodes.draftIncomplete)) {
      return 'Сначала заполните название и адрес квартиры';
    }
    return userMessage;
  }
}
