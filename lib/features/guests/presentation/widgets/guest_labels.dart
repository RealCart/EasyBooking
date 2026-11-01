import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_document_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_gender.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';

/// Shown by actions that have no screen yet: the chat, «Открыть», the menu.
const String guestsComingSoonMessage = 'Скоро будет';

abstract final class GuestCountLabels {
  /// `12 гостей`
  static String guests(int count) {
    return Plural.format(count, one: 'гость', few: 'гостя', many: 'гостей');
  }

  /// `3 договора`
  static String contracts(int count) {
    return Plural.format(
      count,
      one: 'договор',
      few: 'договора',
      many: 'договоров',
    );
  }
}

extension GuestGenderLabels on GuestGender {
  /// `выехал` / `выехала`
  String get checkedOut {
    return switch (this) {
      GuestGender.male => 'выехал',
      GuestGender.female => 'выехала',
    };
  }

  /// `проживал` / `проживала`
  String get stayed {
    return switch (this) {
      GuestGender.male => 'проживал',
      GuestGender.female => 'проживала',
    };
  }
}

extension GuestContractStatusLabels on GuestContractStatus {
  /// `Подписан` or `Ждём подпись`.
  String get label => isAwaitingSignature ? 'Ждём подпись' : 'Подписан';

  Color get color =>
      isAwaitingSignature ? AppColors.warning : AppColors.success;

  /// What happened at `updatedAt`: `Отправлен`, `Открыт`, `Подписан`.
  String get eventLabel {
    return switch (this) {
      GuestContractStatus.sent => 'Отправлен',
      GuestContractStatus.opened => 'Открыт гостем',
      GuestContractStatus.signed => 'Подписан',
    };
  }
}

extension GuestContractLabels on GuestContractEntity {
  /// `№ EB-1048`
  String get title => '№ $number';

  /// `Подписан 18 октября`
  String get statusDetails {
    return '${status.eventLabel} ${DateFormatter.dayMonth(updatedAt)}';
  }

  /// `Айжан Сарсенова · Esentai City · 84`, for the «Договоры» tab.
  String get guestDetails => '$guestName · $propertyName · $unit';
}

extension GuestDocumentLabels on GuestDocumentEntity {
  String get title {
    return switch (kind) {
      GuestDocumentKind.idCard => 'Удостоверение личности',
      GuestDocumentKind.passport => 'Паспорт',
    };
  }

  /// `Проверено 18 октября` or `Ждёт проверки · загружен 30 октября`.
  String get statusDetails {
    final String date = DateFormatter.dayMonth(updatedAt);
    return switch (status) {
      GuestDocumentStatus.verified => 'Проверено $date',
      GuestDocumentStatus.pending => 'Ждёт проверки · загружен $date',
    };
  }

  Color get statusColor {
    return switch (status) {
      GuestDocumentStatus.verified => AppColors.success,
      GuestDocumentStatus.pending => AppColors.warning,
    };
  }
}

extension GuestStayLabels on GuestStayEntity {
  /// `Esentai City · 84`
  String get title => '$propertyName · $unit';

  /// `22–25 октября · 3 ночи`
  String get details {
    final String nightsLabel = Plural.format(
      nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );
    return '${DateFormatter.dayRange(checkIn, checkOut)} · $nightsLabel';
  }
}

extension GuestSummaryLabels on GuestSummaryEntity {
  /// `Esentai City · 22–25 октября`, `Samal Residence · заезд сегодня`,
  /// `Mega Towers · выехал сегодня`, `Esentai City · проживала в сентябре`;
  /// the phone when the guest has no stay.
  String details({required DateTime now}) {
    final GuestStayEntity? stay = latestStay;
    if (stay == null) {
      return phone;
    }
    return '${stay.propertyName} · ${_activity(stay, now)}';
  }

  /// A signed contract for a stay that is over needs no attention, so the
  /// row shows a chevron instead of a status.
  bool get isSettled {
    return latestContractStatus == GuestContractStatus.signed &&
        latestStay?.status == GuestStayStatus.past;
  }

  String _activity(GuestStayEntity stay, DateTime now) {
    switch (stay.status) {
      case GuestStayStatus.upcoming:
        return switch (_dayDifference(stay.checkIn, now)) {
          0 => 'заезд сегодня',
          1 => 'заезд завтра',
          _ => 'заезд ${DateFormatter.dayMonth(stay.checkIn)}',
        };
      case GuestStayStatus.current:
        return DateFormatter.dayRange(stay.checkIn, stay.checkOut);
      case GuestStayStatus.past:
        final DateTime checkOut = stay.checkOut;
        switch (_dayDifference(checkOut, now)) {
          case 0:
            return '${gender.checkedOut} сегодня';
          case -1:
            return '${gender.checkedOut} вчера';
        }
        if (checkOut.year == now.year && checkOut.month == now.month) {
          return '${gender.checkedOut} ${DateFormatter.dayMonth(checkOut)}';
        }
        final String year = checkOut.year == now.year
            ? ''
            : ' ${checkOut.year}';
        return '${gender.stayed} в ${_monthsPrepositional[checkOut.month - 1]}'
            '$year';
    }
  }

  // Calendar days, so a DST change does not shift the difference.
  static int _dayDifference(DateTime date, DateTime now) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  static const List<String> _monthsPrepositional = <String>[
    'январе',
    'феврале',
    'марте',
    'апреле',
    'мае',
    'июне',
    'июле',
    'августе',
    'сентябре',
    'октябре',
    'ноябре',
    'декабре',
  ];
}
