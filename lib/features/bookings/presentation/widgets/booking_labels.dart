import 'package:easy_booking/core/presentation/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_feedback_tone.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_availability_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// Shown by actions that have no screen yet, such as «Изменить».
const String bookingsComingSoonMessage = 'Скоро будет';

extension BookingStatusLabels on BookingStatus {
  /// Text of the status badge.
  String get label {
    return switch (this) {
      BookingStatus.pending => 'Ожидает оплаты',
      BookingStatus.confirmed => 'Подтверждено',
      BookingStatus.checkedIn => 'Живёт',
      BookingStatus.completed => 'Завершено',
      BookingStatus.cancelled => 'Отменено',
    };
  }

  AppStatusBadgeVariant get badgeVariant {
    return switch (this) {
      BookingStatus.pending => AppStatusBadgeVariant.warning,
      BookingStatus.confirmed => AppStatusBadgeVariant.success,
      BookingStatus.checkedIn => AppStatusBadgeVariant.info,
      BookingStatus.completed => AppStatusBadgeVariant.neutral,
      BookingStatus.cancelled => AppStatusBadgeVariant.error,
    };
  }
}

extension BookingSourceLabels on BookingSource {
  String get label {
    return switch (this) {
      BookingSource.airbnb => 'Airbnb',
      BookingSource.bookingCom => 'Booking.com',
      BookingSource.krisha => 'Krisha',
      BookingSource.direct => 'Напрямую',
      BookingSource.other => 'Другое',
    };
  }
}

abstract final class BookingCountLabels {
  /// `3 ночи`
  static String nights(int count) {
    return Plural.format(count, one: 'ночь', few: 'ночи', many: 'ночей');
  }

  /// `2 гостя`
  static String guests(int count) {
    return Plural.format(count, one: 'гость', few: 'гостя', many: 'гостей');
  }
}

extension BookingLabels on BookingEntity {
  /// `Airbnb · HM73P2`, or only the source without a channel code.
  String get sourceDetails {
    final String? code = externalCode;
    return code == null || code.isEmpty
        ? source.label
        : '${source.label} · $code';
  }

  /// `22–25 октября · 3 ночи · 2 гостя`; the guests are omitted when not
  /// specified.
  String get stayDetails {
    final int? count = guestCount;
    return <String>[
      DateFormatter.dayRange(checkIn, checkOut),
      BookingCountLabels.nights(nights),
      if (count != null) BookingCountLabels.guests(count),
    ].join(' · ');
  }

  /// `Esentai City · 84`
  String get apartmentTitle => '$propertyName · $unit';

  /// `EC` for `Esentai City`.
  String get apartmentInitials => _initials(propertyName);

  /// `Заезд 14:00 · выезд 12:00`
  String get checkTimes {
    return 'Заезд ${DateFormatter.time(checkIn)} · '
        'выезд ${DateFormatter.time(checkOut)}';
  }

  /// `127 500 ₸`, or `127 500 ₸ · оплачено` when paid in advance.
  String get priceDetails {
    final String price = MoneyFormatter.tenge(totalPrice);
    return isPaid ? '$price · оплачено' : price;
  }

  /// `50 000 ₸ · не внесён`, or `Без депозита`.
  String get depositDetails {
    if (deposit == 0) {
      return 'Без депозита';
    }
    final String amount = MoneyFormatter.tenge(deposit);
    return isDepositPaid ? '$amount · внесён' : '$amount · не внесён';
  }
}

/// Texts of the contract banner of a booking.
extension BookingContractLabels on BookingContractEntity? {
  String get title {
    final BookingContractEntity? contract = this;
    if (contract == null) {
      return 'Договор не создан';
    }
    return switch (contract.status) {
      BookingContractStatus.draft => 'Договор не отправлен',
      BookingContractStatus.awaitingSignature => 'Договор ожидает подписи',
      BookingContractStatus.signed => 'Договор подписан',
    };
  }

  /// `Отправлен сегодня, 10:12`
  String details({required DateTime now}) {
    final BookingContractEntity? contract = this;
    if (contract == null) {
      return 'Для этой брони договор не оформляли';
    }
    final DateTime? sentAt = contract.sentAt;
    final DateTime? signedAt = contract.signedAt;
    return switch (contract.status) {
      BookingContractStatus.draft => 'Создан и ждёт отправки гостю',
      BookingContractStatus.awaitingSignature =>
        sentAt == null
            ? 'Отправлен гостю'
            : 'Отправлен ${DateFormatter.relativeDayTime(sentAt, now: now)}',
      BookingContractStatus.signed =>
        signedAt == null
            ? 'Подписан гостем'
            : 'Подписан ${DateFormatter.relativeDayTime(signedAt, now: now)}',
    };
  }

  AppFeedbackTone get tone {
    final BookingContractEntity? contract = this;
    if (contract == null) {
      return AppFeedbackTone.info;
    }
    return switch (contract.status) {
      BookingContractStatus.draft => AppFeedbackTone.info,
      BookingContractStatus.awaitingSignature => AppFeedbackTone.warning,
      BookingContractStatus.signed => AppFeedbackTone.success,
    };
  }
}

extension BookingDraftLabels on BookingDraftEntity {
  /// `Esentai City · 28–31 октября`
  String get summary {
    return '$propertyName · ${DateFormatter.dayRange(checkIn, checkOut)}';
  }
}

extension BookingAvailabilityLabels on BookingAvailabilityEntity {
  String get title => isAvailable ? 'Даты свободны' : 'Даты заняты';

  /// `Проверено по Airbnb, Booking.com и локальному календарю.`
  String get details {
    if (!isAvailable) {
      return 'Даты пересекаются с другой бронью. Вернитесь назад и '
          'измените даты.';
    }
    final List<String> sources = <String>[
      ...checkedChannelNames,
      'локальному календарю',
    ];
    final String joined = sources.length == 1
        ? sources.single
        : '${sources.sublist(0, sources.length - 1).join(', ')} '
              'и ${sources.last}';
    return 'Проверено по $joined.';
  }
}

extension BookingGuestLabels on BookingGuestEntity {
  /// `АС` for `Айжан Сарсенова`.
  String get initials => _initials(fullName);
}

extension BookingPropertyLabels on PropertyEntity {
  /// `Esentai City · 84`, the picked apartment in «Квартира».
  String get bookingTitle => '$name · $unit';

  /// `Алматы · Аль-Фараби, 77/8`, under the apartment in the picker.
  String get bookingSubtitle => '$city · $address';
}

String _initials(String value) {
  final List<String> parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.single.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
