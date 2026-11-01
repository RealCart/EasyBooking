import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';

/// Everything «Безопасность» shows.
final class SecurityOverviewEntity extends Equatable {
  const SecurityOverviewEntity({
    required this.phone,
    required this.isPhoneVerified,
    required this.appCodeChangedAt,
    required this.isBiometricLoginEnabled,
    required this.sessions,
    required this.recentEvents,
    required this.receivedAt,
  });

  /// The sign-in phone in E.164, such as `+77012345678`.
  final String phone;
  final bool isPhoneVerified;

  /// When the app code was last changed, or `null` if it was never set.
  final DateTime? appCodeChangedAt;

  /// «Вход по Face ID»: biometrics confirm opening contracts.
  final bool isBiometricLoginEnabled;

  /// The current session first, then the others by last activity.
  final List<ActiveSessionEntity> sessions;

  /// Newest first.
  final List<SecurityEventEntity> recentEvents;

  /// The source's current time when it answered: the reference for the
  /// relative labels of [recentEvents] («Сегодня, 09:41»).
  final DateTime receivedAt;

  /// Sessions that «Завершить другие сеансы» would end.
  List<ActiveSessionEntity> get otherSessions {
    return sessions
        .where((ActiveSessionEntity session) => !session.isCurrent)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => <Object?>[
    phone,
    isPhoneVerified,
    appCodeChangedAt,
    isBiometricLoginEnabled,
    sessions,
    recentEvents,
    receivedAt,
  ];
}
