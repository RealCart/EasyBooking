import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_file_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_stay_entity.dart';

/// Shown by actions that have no screen yet: «Заменить», «Открыть», PDF.
const String contractsComingSoonMessage = 'Скоро будет';

extension ContractFailureMessage on Failure {
  /// Text for a contracts failure. Known codes get their own message;
  /// anything else falls back to the shared [userMessage].
  String get contractMessage {
    final String? code = switch (this) {
      ValidationFailure(:final String? code) => code,
      ServerFailure(:final String? code) => code,
      _ => null,
    };
    return switch (code) {
      ContractErrorCodes.alreadySigned =>
        'Договор уже подписан, изменить его нельзя',
      ContractErrorCodes.invalidPhone => FormValidators.invalidPhoneMessage,
      ContractErrorCodes.invalidEmail => FormValidators.invalidEmailMessage,
      _ => userMessage,
    };
  }

  /// Whether the contract could not be found, so retrying does not help.
  bool get isContractMissing {
    return switch (this) {
      ServerFailure(statusCode: 404) => true,
      _ => false,
    };
  }
}

/// Text for a `ContractGuestState.fieldErrors` value, or `null` when the
/// field has no error. Server texts are not shown as is because their
/// wording is not controlled by the app.
String? contractFieldErrorMessage(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  return switch (code) {
    ContractErrorCodes.required => FormValidators.requiredMessage,
    ContractErrorCodes.invalidIin => FormValidators.invalidIinMessage,
    ContractErrorCodes.invalidIdNumber => FormValidators.invalidIdNumberMessage,
    _ => 'Проверьте поле',
  };
}

extension ContractStatusLabels on ContractStatus {
  /// `черновик`, as in «Договор № EB-1052 · черновик».
  String get shortLabel {
    return switch (this) {
      ContractStatus.draft => 'черновик',
      ContractStatus.sent => 'отправлен',
      ContractStatus.opened => 'открыт гостем',
      ContractStatus.signed => 'подписан',
    };
  }

  /// `Ожидает подписи гостя`, shown above the contract number.
  String get label {
    return switch (this) {
      ContractStatus.draft => 'Черновик · не отправлен',
      ContractStatus.sent || ContractStatus.opened => 'Ожидает подписи гостя',
      ContractStatus.signed => 'Подписан гостем',
    };
  }

  Color get color {
    return switch (this) {
      ContractStatus.draft => AppColors.secondaryText,
      ContractStatus.sent || ContractStatus.opened => AppColors.warning,
      ContractStatus.signed => AppColors.success,
    };
  }
}

extension ContractDeliveryChannelLabels on ContractDeliveryChannel {
  /// Chip label in the recipient sheet.
  String get label {
    return switch (this) {
      ContractDeliveryChannel.sms => 'SMS',
      ContractDeliveryChannel.whatsApp => 'WhatsApp',
      ContractDeliveryChannel.email => 'Почта',
    };
  }

  /// `Ссылка на договор в SMS`
  String get linkDescription {
    return switch (this) {
      ContractDeliveryChannel.sms => 'Ссылка на договор в SMS',
      ContractDeliveryChannel.whatsApp => 'Ссылка на договор в WhatsApp',
      ContractDeliveryChannel.email => 'Ссылка на договор на почту',
    };
  }

  /// `Отправлен по SMS`
  String get sentLabel {
    return switch (this) {
      ContractDeliveryChannel.sms => 'Отправлен по SMS',
      ContractDeliveryChannel.whatsApp => 'Отправлен в WhatsApp',
      ContractDeliveryChannel.email => 'Отправлен на почту',
    };
  }
}

extension ContractRecipientLabels on ContractRecipientEntity {
  /// The address with a masked phone: `+7 700 ••• 45 21` or an email.
  String get maskedAddress {
    return channel.usesPhone ? ContractMask.phone(address) : address;
  }
}

extension ContractHistoryLabels on ContractHistoryEntryEntity {
  String get title {
    return switch (kind) {
      ContractHistoryKind.created => 'Создан',
      ContractHistoryKind.sent =>
        recipient?.channel.sentLabel ?? 'Отправлен гостю',
      ContractHistoryKind.opened => 'Открыт гостем',
      ContractHistoryKind.signed => 'Подписан',
    };
  }

  /// `Сегодня, 10:12 · +7 701 ••• 04 18`
  String subtitle({required DateTime now}) {
    final String time = ContractTimeLabels.relativeDayTime(at, now: now);
    final ContractRecipientEntity? recipient = this.recipient;
    return recipient == null ? time : '$time · ${recipient.maskedAddress}';
  }
}

extension ContractStayLabels on ContractStayEntity {
  /// `Samal Residence · 12`
  String get propertyTitle => '$propertyName · $unit';

  /// `22–24 октября · 2 ночи`
  String get datesAndNights {
    final String nightsLabel = Plural.format(
      nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );
    return '${DateFormatter.dayRange(checkIn, checkOut)} · $nightsLabel';
  }

  /// `18:30 / 12:00`
  String get checkInOutTimes {
    return '${DateFormatter.time(checkIn)} / ${DateFormatter.time(checkOut)}';
  }
}

extension ContractFileLabels on ContractFileEntity {
  /// `2 страницы · 842 КБ`
  String get pagesAndSize => '${_pages(pageCount)} · ${_size(sizeBytes)}';

  /// `3 страницы · русский язык`, or [pagesAndSize] without a language.
  String get pagesAndLanguage {
    final String? language = this.language;
    return language == null ? pagesAndSize : '${_pages(pageCount)} · $language';
  }

  static String _pages(int count) {
    return Plural.format(
      count,
      one: 'страница',
      few: 'страницы',
      many: 'страниц',
    );
  }

  static String _size(int bytes) {
    const int kilobyte = 1024;
    const int megabyte = kilobyte * 1024;
    if (bytes >= megabyte) {
      return '${(bytes / megabyte).toStringAsFixed(1).replaceAll('.', ',')} МБ';
    }
    final int kilobytes = (bytes / kilobyte).ceil();
    return '${kilobytes < 1 ? 1 : kilobytes} КБ';
  }
}

abstract final class ContractTimeLabels {
  /// `Сегодня, 09:54`
  static String relativeDayTime(DateTime date, {required DateTime now}) {
    final String value = DateFormatter.relativeDayTime(date, now: now);
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }

  /// `Напомнить через 2 часа`, or `null` when no reminder is scheduled.
  static String? reminder({
    required DateTime? remindAt,
    required DateTime now,
  }) {
    if (remindAt == null) {
      return null;
    }
    final Duration left = remindAt.difference(now);
    if (left.inMinutes < 1) {
      return 'Напоминание отправляется';
    }
    if (left.inMinutes < 60) {
      return 'Напомнить через ${Plural.format(left.inMinutes, one: 'минуту', few: 'минуты', many: 'минут')}';
    }
    final int hours = (left.inMinutes / 60).round();
    return 'Напомнить через ${Plural.format(hours, one: 'час', few: 'часа', many: 'часов')}';
  }
}

/// Hides personal data on screen.
abstract final class ContractMask {
  static const String bullet = '•';

  /// `+7 700 ••• 45 21`. Returns [input] unchanged when it is not a
  /// Kazakhstan number.
  static String phone(String input) {
    final String? national = PhoneNumber.toNational(input);
    if (national == null) {
      return input;
    }
    return '${PhoneNumber.countryCode} ${national.substring(0, 3)} '
        '${bullet * 3} ${national.substring(6, 8)} ${national.substring(8)}';
  }

  /// Replaces every character but the last [visibleTail] ones with a bullet,
  /// keeping spaces, so the masked text has the same length.
  static String tail(String value, {required int visibleTail}) {
    final int maskedLength = value.length - visibleTail;
    if (maskedLength <= 0) {
      return value;
    }
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < value.length; index++) {
      final String character = value[index];
      buffer.write(
        index < maskedLength && character != ' ' ? bullet : character,
      );
    }
    return buffer.toString();
  }
}
