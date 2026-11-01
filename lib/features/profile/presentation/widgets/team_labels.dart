import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/extensions/string_extensions.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';

/// Roles an invitation can assign, in the order of «Роли».
const List<ProfileRole> teamAssignableRoles = <ProfileRole>[
  ProfileRole.manager,
  ProfileRole.checkInOperator,
  ProfileRole.cleaner,
];

extension TeamRoleLabels on ProfileRole {
  /// The role on «Команда и доступ», where the cleaner is «Уборка».
  String get teamLabel {
    return switch (this) {
      ProfileRole.owner => 'Владелец',
      ProfileRole.manager => 'Менеджер',
      ProfileRole.checkInOperator => 'Оператор заселения',
      ProfileRole.cleaner => 'Уборка',
    };
  }

  /// What the role works with, after the property count of a member.
  String get accessSummary {
    return switch (this) {
      ProfileRole.owner => 'полный доступ',
      ProfileRole.manager => 'брони и гости',
      ProfileRole.checkInOperator => 'заезды и инструкции',
      ProfileRole.cleaner => 'календарь задач',
    };
  }

  /// The «Роли» explanation.
  String get description {
    return switch (this) {
      ProfileRole.owner => 'Полный доступ ко всем объектам и настройкам.',
      ProfileRole.manager =>
        'Брони, гости, договоры и цены выбранных объектов.',
      ProfileRole.checkInOperator =>
        'Контакты гостя, время заезда и инструкции.',
      ProfileRole.cleaner => 'Только календарь выездов и готовность объекта.',
    };
  }

  /// The bar in front of the role in «Роли».
  Color get accentColor {
    return switch (this) {
      ProfileRole.owner => AppColors.text,
      ProfileRole.manager => AppColors.accent,
      ProfileRole.checkInOperator => AppColors.info,
      ProfileRole.cleaner => AppColors.success,
    };
  }
}

extension TeamMemberLabels on TeamMemberEntity {
  String get initials => fullName.initials;

  /// `Все объекты · полный доступ`, `4 объекта · брони и гости`, or
  /// `Приглашение до 3 ноября` while the invitation is pending.
  String get accessLabel {
    if (status == TeamMemberStatus.invited) {
      final DateTime? expiresAt = inviteExpiresAt;
      return expiresAt == null
          ? 'Приглашение отправлено'
          : 'Приглашение до ${DateFormatter.dayMonth(expiresAt)}';
    }
    final String properties = hasAllProperties
        ? 'Все объекты'
        : Plural.format(
            propertyCount,
            one: 'объект',
            few: 'объекта',
            many: 'объектов',
          );
    return '$properties · ${role.accessSummary}';
  }
}

/// `3 участника`
String teamMemberCountLabel(int count) {
  return Plural.format(
    count,
    one: 'участник',
    few: 'участника',
    many: 'участников',
  );
}
