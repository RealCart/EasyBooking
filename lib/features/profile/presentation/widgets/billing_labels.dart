import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invoice_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/payment_card_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/plan_usage_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

extension BillingOverviewLabels on BillingOverviewEntity {
  /// `3 990 ₸ в месяц`, or `Бесплатно`.
  String get priceLabel {
    return monthlyPrice == 0
        ? 'Бесплатно'
        : '${MoneyFormatter.tenge(monthlyPrice)} в месяц';
  }

  /// `Следующее списание 15 ноября`, or `null` when nothing is charged.
  String? get nextChargeLabel {
    final DateTime? chargeAt = nextChargeAt;
    return chargeAt == null
        ? null
        : 'Следующее списание ${DateFormatter.dayMonth(chargeAt)}';
  }
}

extension SubscriptionPlanDescriptions on SubscriptionPlan {
  /// What the plan gives, in the plan choice: `До 5 объектов и 2
  /// участников`, `До 10 объектов, 5 участников и договоры`.
  String get description {
    final String properties = _upTo(
      _propertyLimit,
      one: 'объекта',
      many: 'объектов',
    );
    final String members = _upTo(
      _memberLimit,
      one: 'участника',
      many: 'участников',
    );
    return switch (this) {
      SubscriptionPlan.free => 'До $properties и $members',
      SubscriptionPlan.pro => 'До $properties, $members и договоры',
    };
  }

  // The plan limits are not part of the domain yet; they mirror the plan
  // terms of the data source, so each limit is written here only once.
  int get _propertyLimit {
    return switch (this) {
      SubscriptionPlan.free => 5,
      SubscriptionPlan.pro => 10,
    };
  }

  int get _memberLimit {
    return switch (this) {
      SubscriptionPlan.free => 2,
      SubscriptionPlan.pro => 5,
    };
  }

  /// `5 объектов` after «до»: the genitive singular for 1, 21, 31, …, the
  /// genitive plural otherwise.
  static String _upTo(int count, {required String one, required String many}) {
    final bool isSingular = count % 10 == 1 && count % 100 != 11;
    return '$count ${isSingular ? one : many}';
  }
}

extension PlanUsageLabels on PlanUsageEntity {
  /// `4 из 10`
  String get label => '$used из $limit';
}

extension PaymentCardLabels on PaymentCardEntity {
  String get brandLabel {
    return switch (brand) {
      PaymentCardBrand.visa => 'VISA',
      PaymentCardBrand.mastercard => 'MC',
    };
  }

  /// `•••• 4218`
  String get maskedNumber => '•••• $lastDigits';
}

extension InvoiceLabels on InvoiceEntity {
  /// `Счёт за октябрь`
  String get title {
    // `monthYear` is `Октябрь 2026`; the month alone reads in lowercase.
    final String month = DateFormatter.monthYear(period).split(' ').first;
    return 'Счёт за ${month.toLowerCase()}';
  }

  String get amountLabel => MoneyFormatter.tenge(amount);
}
