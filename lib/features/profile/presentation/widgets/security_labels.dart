import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';

extension SecurityOverviewLabels on SecurityOverviewEntity {
  /// `+7 701 234 56 78 · подтверждён`
  String get phoneLabel {
    final String state = isPhoneVerified ? 'подтверждён' : 'не подтверждён';
    return '${PhoneNumber.format(phone)} · $state';
  }

  /// `Изменён 12 сентября`, or `Не задан`.
  String get appCodeLabel {
    final DateTime? changedAt = appCodeChangedAt;
    return changedAt == null
        ? 'Не задан'
        : 'Изменён ${DateFormatter.dayMonth(changedAt)}';
  }

  /// `Потребуется повторный вход на MacBook Air.`
  String get terminateOthersHint {
    final String devices = otherSessions
        .map((ActiveSessionEntity session) => session.deviceName)
        .join(', ');
    return 'Потребуется повторный вход на $devices.';
  }
}

extension ActiveSessionLabels on ActiveSessionEntity {
  /// `Алматы · сейчас` for this device, otherwise
  /// `Алматы · 26 октября, 21:14`.
  String get activityLabel {
    final String activity = isCurrent
        ? 'сейчас'
        : '${DateFormatter.dayMonth(lastActiveAt)}, '
              '${DateFormatter.time(lastActiveAt)}';
    return '$city · $activity';
  }
}

extension SecurityEventLabels on SecurityEventEntity {
  String get title {
    return switch (kind) {
      SecurityEventKind.signedIn => 'Успешный вход',
      SecurityEventKind.appCodeChanged => 'Код приложения изменён',
      SecurityEventKind.otherSessionsTerminated => 'Другие сеансы завершены',
    };
  }

  /// `Сегодня, 09:41 · iPhone`
  String subtitle({required DateTime now}) {
    final String time = DateFormatter.relativeDayTime(occurredAt, now: now);
    final String capitalized = time[0].toUpperCase() + time.substring(1);
    final String? device = deviceName;
    return device == null ? capitalized : '$capitalized · $device';
  }
}
