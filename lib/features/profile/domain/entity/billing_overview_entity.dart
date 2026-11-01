import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/invoice_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/payment_card_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/plan_usage_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

/// Everything «Тариф и оплата» shows.
final class BillingOverviewEntity extends Equatable {
  const BillingOverviewEntity({
    required this.plan,
    required this.isActive,
    required this.monthlyPrice,
    required this.nextChargeAt,
    required this.propertyUsage,
    required this.memberUsage,
    required this.includedFeatures,
    required this.paymentCard,
    required this.latestInvoice,
  });

  final SubscriptionPlan plan;

  /// «Активен».
  final bool isActive;

  /// In tenge; `0` for [SubscriptionPlan.free].
  final int monthlyPrice;

  /// «Следующее списание»; `null` when nothing will be charged.
  final DateTime? nextChargeAt;

  /// «Объекты».
  final PlanUsageEntity propertyUsage;

  /// «Участники команды», including the owner.
  final PlanUsageEntity memberUsage;

  /// «Включено в тариф», such as `Приоритетная поддержка`.
  final List<String> includedFeatures;
  final PaymentCardEntity? paymentCard;
  final InvoiceEntity? latestInvoice;

  @override
  List<Object?> get props => <Object?>[
    plan,
    isActive,
    monthlyPrice,
    nextChargeAt,
    propertyUsage,
    memberUsage,
    includedFeatures,
    paymentCard,
    latestInvoice,
  ];
}
