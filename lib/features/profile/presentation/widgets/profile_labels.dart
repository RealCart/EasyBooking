import 'package:easy_booking/core/presentation/widgets/content/app_workspace_summary.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

extension ProfileRoleLabels on ProfileRole {
  String get label {
    return switch (this) {
      ProfileRole.owner => 'Владелец',
      ProfileRole.manager => 'Менеджер',
      ProfileRole.checkInOperator => 'Оператор заселения',
      ProfileRole.cleaner => 'Клинер',
    };
  }
}

extension SubscriptionPlanLabels on SubscriptionPlan {
  String get label {
    return switch (this) {
      SubscriptionPlan.free => 'Free',
      SubscriptionPlan.pro => 'Pro',
    };
  }
}

extension ProfileLabels on ProfileEntity {
  /// `Владелец · Алматы`
  String get details => '${role.label} · $city';

  /// `4 квартиры`, `2 в команде`, `Pro ваш тариф`.
  List<AppWorkspaceMetric> get metrics {
    return <AppWorkspaceMetric>[
      AppWorkspaceMetric(
        value: '$propertyCount',
        label: Plural.select(
          propertyCount,
          one: 'квартира',
          few: 'квартиры',
          many: 'квартир',
        ),
      ),
      AppWorkspaceMetric(value: '$teamMemberCount', label: 'в команде'),
      AppWorkspaceMetric(value: plan.label, label: 'ваш тариф'),
    ];
  }
}

extension ProfileCityLabels on CityEntity {
  /// `UTC +5`, or `UTC +5:30` for an offset with minutes.
  String get timeZoneLabel {
    final int totalMinutes = utcOffset.inMinutes;
    final String sign = totalMinutes < 0 ? '-' : '+';
    final int hours = totalMinutes.abs() ~/ Duration.minutesPerHour;
    final int minutes = totalMinutes.abs() % Duration.minutesPerHour;
    final String suffix = minutes == 0
        ? ''
        : ':${minutes.toString().padLeft(2, '0')}';
    return 'UTC $sign$hours$suffix';
  }
}
